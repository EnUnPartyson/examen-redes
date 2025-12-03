#!/bin/bash
set -e

# Variables from Terraform
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"
DB_ENDPOINT="${db_endpoint}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
LOG_GROUP="${log_group}"

# Update system
yum update -y

# Install Python 3 and dependencies
yum install -y python3 python3-pip gcc python3-devel mysql-devel

# Install CloudWatch Logs agent
yum install -y amazon-cloudwatch-agent

# Install Python packages
pip3 install --upgrade pip
pip3 install flask flask-cors pymysql SQLAlchemy gunicorn python-dateutil

# Create application directory
mkdir -p /opt/scheduling-api
cd /opt/scheduling-api

# Create the Scheduling API application
cat > /opt/scheduling-api/app.py <<'PYTHON'
from flask import Flask, jsonify, request
from flask_cors import CORS
import pymysql
from datetime import datetime, timedelta
import os
import socket

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': os.environ.get('DB_ENDPOINT', 'localhost').split(':')[0],
    'user': os.environ.get('DB_USER', 'root'),
    'password': os.environ.get('DB_PASSWORD', ''),
    'database': os.environ.get('DB_NAME', 'appointments'),
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db_connection():
    """Create database connection"""
    try:
        connection = pymysql.connect(**DB_CONFIG)
        return connection
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def init_db():
    """Initialize database tables"""
    connection = get_db_connection()
    if connection:
        try:
            with connection.cursor() as cursor:
                # Create appointments table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS appointments (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        client_name VARCHAR(255) NOT NULL,
                        client_email VARCHAR(255) NOT NULL,
                        appointment_date DATETIME NOT NULL,
                        service_type VARCHAR(100) NOT NULL,
                        status VARCHAR(50) DEFAULT 'pending',
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        INDEX idx_date (appointment_date),
                        INDEX idx_status (status)
                    )
                """)
                connection.commit()
                print("Database initialized successfully")
        except Exception as e:
            print(f"Error initializing database: {e}")
        finally:
            connection.close()

# Initialize database on startup
init_db()

@app.route('/api/scheduling/health', methods=['GET'])
def health():
    """Health check endpoint"""
    connection = get_db_connection()
    db_status = 'healthy' if connection else 'unhealthy'
    if connection:
        connection.close()
    
    return jsonify({
        'status': 'healthy',
        'service': 'Scheduling API',
        'hostname': socket.gethostname(),
        'ip': socket.gethostbyname(socket.gethostname()),
        'database': db_status,
        'timestamp': datetime.now().isoformat()
    }), 200 if db_status == 'healthy' else 503

@app.route('/api/scheduling/info', methods=['GET'])
def info():
    """API information endpoint"""
    return jsonify({
        'service': 'Scheduling/Appointment API',
        'version': '1.0.0',
        'endpoints': {
            'health': '/api/scheduling/health',
            'appointments': '/api/scheduling/appointments',
            'appointment_detail': '/api/scheduling/appointments/<id>',
            'available_slots': '/api/scheduling/available-slots'
        },
        'environment': os.environ.get('ENVIRONMENT', 'unknown'),
        'project': os.environ.get('PROJECT_NAME', 'unknown')
    })

@app.route('/api/scheduling/appointments', methods=['GET', 'POST'])
def appointments():
    """Get all appointments or create a new one"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 503
    
    try:
        if request.method == 'GET':
            # Get query parameters
            status = request.args.get('status')
            date_from = request.args.get('date_from')
            date_to = request.args.get('date_to')
            
            with connection.cursor() as cursor:
                query = "SELECT * FROM appointments WHERE 1=1"
                params = []
                
                if status:
                    query += " AND status = %s"
                    params.append(status)
                
                if date_from:
                    query += " AND appointment_date >= %s"
                    params.append(date_from)
                
                if date_to:
                    query += " AND appointment_date <= %s"
                    params.append(date_to)
                
                query += " ORDER BY appointment_date ASC"
                
                cursor.execute(query, params)
                appointments = cursor.fetchall()
                
                # Convert datetime to string
                for apt in appointments:
                    if apt['appointment_date']:
                        apt['appointment_date'] = apt['appointment_date'].isoformat()
                    if apt['created_at']:
                        apt['created_at'] = apt['created_at'].isoformat()
                    if apt['updated_at']:
                        apt['updated_at'] = apt['updated_at'].isoformat()
                
                return jsonify({
                    'total': len(appointments),
                    'appointments': appointments
                })
        
        elif request.method == 'POST':
            data = request.get_json()
            
            # Validate required fields
            required_fields = ['client_name', 'client_email', 'appointment_date', 'service_type']
            for field in required_fields:
                if field not in data:
                    return jsonify({'error': f'Missing required field: {field}'}), 400
            
            with connection.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO appointments 
                    (client_name, client_email, appointment_date, service_type, notes, status)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    data['client_name'],
                    data['client_email'],
                    data['appointment_date'],
                    data['service_type'],
                    data.get('notes', ''),
                    data.get('status', 'pending')
                ))
                connection.commit()
                appointment_id = cursor.lastrowid
                
                return jsonify({
                    'message': 'Appointment created successfully',
                    'appointment_id': appointment_id
                }), 201
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        connection.close()

@app.route('/api/scheduling/appointments/<int:appointment_id>', methods=['GET', 'PUT', 'DELETE'])
def appointment_detail(appointment_id):
    """Get, update or delete a specific appointment"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 503
    
    try:
        if request.method == 'GET':
            with connection.cursor() as cursor:
                cursor.execute("SELECT * FROM appointments WHERE id = %s", (appointment_id,))
                appointment = cursor.fetchone()
                
                if not appointment:
                    return jsonify({'error': 'Appointment not found'}), 404
                
                # Convert datetime to string
                if appointment['appointment_date']:
                    appointment['appointment_date'] = appointment['appointment_date'].isoformat()
                if appointment['created_at']:
                    appointment['created_at'] = appointment['created_at'].isoformat()
                if appointment['updated_at']:
                    appointment['updated_at'] = appointment['updated_at'].isoformat()
                
                return jsonify(appointment)
        
        elif request.method == 'PUT':
            data = request.get_json()
            
            with connection.cursor() as cursor:
                # Build update query dynamically
                update_fields = []
                params = []
                
                for field in ['client_name', 'client_email', 'appointment_date', 'service_type', 'status', 'notes']:
                    if field in data:
                        update_fields.append(f"{field} = %s")
                        params.append(data[field])
                
                if not update_fields:
                    return jsonify({'error': 'No fields to update'}), 400
                
                params.append(appointment_id)
                query = f"UPDATE appointments SET {', '.join(update_fields)} WHERE id = %s"
                
                cursor.execute(query, params)
                connection.commit()
                
                if cursor.rowcount == 0:
                    return jsonify({'error': 'Appointment not found'}), 404
                
                return jsonify({'message': 'Appointment updated successfully'})
        
        elif request.method == 'DELETE':
            with connection.cursor() as cursor:
                cursor.execute("DELETE FROM appointments WHERE id = %s", (appointment_id,))
                connection.commit()
                
                if cursor.rowcount == 0:
                    return jsonify({'error': 'Appointment not found'}), 404
                
                return jsonify({'message': 'Appointment deleted successfully'})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        connection.close()

@app.route('/api/scheduling/available-slots', methods=['GET'])
def available_slots():
    """Get available time slots for a given date"""
    date_str = request.args.get('date')
    if not date_str:
        return jsonify({'error': 'Date parameter is required'}), 400
    
    try:
        date = datetime.fromisoformat(date_str)
    except ValueError:
        return jsonify({'error': 'Invalid date format. Use ISO format (YYYY-MM-DD)'}), 400
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 503
    
    try:
        with connection.cursor() as cursor:
            # Get booked appointments for the date
            cursor.execute("""
                SELECT DATE_FORMAT(appointment_date, '%%H:%%i') as time_slot
                FROM appointments
                WHERE DATE(appointment_date) = %s
                AND status != 'cancelled'
                ORDER BY appointment_date
            """, (date.date(),))
            
            booked_slots = [row['time_slot'] for row in cursor.fetchall()]
            
            # Generate time slots (9 AM to 5 PM, every hour)
            all_slots = []
            start_hour = 9
            end_hour = 17
            
            for hour in range(start_hour, end_hour):
                slot_time = f"{hour:02d}:00"
                all_slots.append({
                    'time': slot_time,
                    'available': slot_time not in booked_slots
                })
            
            return jsonify({
                'date': date_str,
                'slots': all_slots,
                'total_slots': len(all_slots),
                'available_slots': len([s for s in all_slots if s['available']])
            })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        connection.close()

@app.route('/api/scheduling/statistics', methods=['GET'])
def statistics():
    """Get appointment statistics"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 503
    
    try:
        with connection.cursor() as cursor:
            stats = {}
            
            # Total appointments
            cursor.execute("SELECT COUNT(*) as total FROM appointments")
            stats['total_appointments'] = cursor.fetchone()['total']
            
            # By status
            cursor.execute("""
                SELECT status, COUNT(*) as count 
                FROM appointments 
                GROUP BY status
            """)
            stats['by_status'] = {row['status']: row['count'] for row in cursor.fetchall()}
            
            # By service type
            cursor.execute("""
                SELECT service_type, COUNT(*) as count 
                FROM appointments 
                GROUP BY service_type
            """)
            stats['by_service'] = {row['service_type']: row['count'] for row in cursor.fetchall()}
            
            # Upcoming appointments
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM appointments 
                WHERE appointment_date >= NOW()
                AND status = 'pending'
            """)
            stats['upcoming'] = cursor.fetchone()['count']
            
            return jsonify(stats)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        connection.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)
PYTHON

# Set environment variables
cat > /opt/scheduling-api/.env <<ENV
PROJECT_NAME=$PROJECT_NAME
ENVIRONMENT=$ENVIRONMENT
DB_ENDPOINT=$DB_ENDPOINT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
ENV

# Create systemd service
cat > /etc/systemd/system/scheduling-api.service <<SERVICE
[Unit]
Description=Scheduling API Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/scheduling-api
EnvironmentFile=/opt/scheduling-api/.env
ExecStart=/usr/bin/gunicorn --workers 4 --bind 0.0.0.0:8000 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Set permissions
chown -R ec2-user:ec2-user /opt/scheduling-api

# Configure CloudWatch Logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWCONFIG
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}/system"
          }
        ]
      }
    }
  }
}
CWCONFIG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Start the service
systemctl daemon-reload
systemctl enable scheduling-api
systemctl start scheduling-api

# Wait for service to be ready
sleep 5

# Check service status
systemctl status scheduling-api

echo "Scheduling API deployed successfully!"
