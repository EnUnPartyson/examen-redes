# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.web_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-alb"
      Environment = var.environment
    },
    var.tags
  )
}

# Target Group for Web Servers
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-web-tg"
      Environment = var.environment
    },
    var.tags
  )
}

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Launch Template for Web Servers
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type_web

  key_name = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [var.web_security_group_id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              # Create a simple web page
              cat > /var/www/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Examen Redes - Web Server</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          margin: 0;
                          padding: 0;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          color: white;
                          display: flex;
                          justify-content: center;
                          align-items: center;
                          min-height: 100vh;
                      }
                      .container {
                          text-align: center;
                          background: rgba(255,255,255,0.1);
                          padding: 50px;
                          border-radius: 20px;
                          backdrop-filter: blur(10px);
                      }
                      h1 { font-size: 3em; margin: 0; }
                      p { font-size: 1.5em; }
                      .info { 
                          background: rgba(0,0,0,0.2);
                          padding: 20px;
                          border-radius: 10px;
                          margin-top: 30px;
                      }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🌐 Servidor Web Activo</h1>
                      <p>Examen de Redes de Computadores</p>
                      <div class="info">
                          <p><strong>Hostname:</strong> $(hostname)</p>
                          <p><strong>IP Privada:</strong> $(hostname -I | awk '{print $1}')</p>
                          <p><strong>Zona de Disponibilidad:</strong> $(ec2-metadata --availability-zone | cut -d " " -f 2)</p>
                      </div>
                  </div>
              </body>
              </html>
              HTML
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-web"
        Environment = var.environment
        Layer       = "Web"
      },
      var.tags
    )
  }
}

# Auto Scaling Group for Web Servers
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Launch Template for Application Servers
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-app-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type_app

  key_name = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [var.app_security_group_id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 python3-pip
              
              # Install Flask for API
              pip3 install flask
              
              # Create a simple API
              mkdir -p /opt/api
              cat > /opt/api/app.py <<'PYTHON'
              from flask import Flask, jsonify
              import socket
              import os
              
              app = Flask(__name__)
              
              @app.route('/api/health')
              def health():
                  return jsonify({
                      'status': 'healthy',
                      'service': 'Application Server',
                      'hostname': socket.gethostname(),
                      'ip': socket.gethostbyname(socket.gethostname())
                  })
              
              @app.route('/api/info')
              def info():
                  return jsonify({
                      'service': 'API REST',
                      'version': '1.0.0',
                      'environment': '${var.environment}',
                      'project': '${var.project_name}'
                  })
              
              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=8080)
              PYTHON
              
              # Create systemd service
              cat > /etc/systemd/system/api.service <<'SERVICE'
              [Unit]
              Description=Flask API Service
              After=network.target
              
              [Service]
              Type=simple
              User=ec2-user
              WorkingDirectory=/opt/api
              ExecStart=/usr/bin/python3 /opt/api/app.py
              Restart=always
              
              [Install]
              WantedBy=multi-user.target
              SERVICE
              
              chown -R ec2-user:ec2-user /opt/api
              systemctl daemon-reload
              systemctl start api
              systemctl enable api
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-app"
        Environment = var.environment
        Layer       = "Application"
      },
      var.tags
    )
  }
}

# Auto Scaling Group for Application Servers
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-${var.environment}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# RDS MySQL Database
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-${var.environment}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  
  db_name  = "examenredes"
  username = "admin"
  password = "ChangeMe123!"  # En producción usar AWS Secrets Manager
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = false
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db"
      Environment = var.environment
      Layer       = "Database"
    },
    var.tags
  )
}
