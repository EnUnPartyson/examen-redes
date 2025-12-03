# Módulo de API de Agendamiento

Este módulo implementa una API REST completa para sistema de agendamiento/citas.

## 🎯 Características

### Funcionalidades:
- ✅ **CRUD de Citas**: Crear, leer, actualizar y eliminar citas
- ✅ **Disponibilidad**: Consultar horarios disponibles
- ✅ **Estadísticas**: Métricas de uso del sistema
- ✅ **Filtros**: Búsqueda por estado, fecha, tipo de servicio
- ✅ **Base de Datos**: Integración con MySQL/RDS
- ✅ **Auto Scaling**: Escalado automático por CPU
- ✅ **Health Checks**: Monitoreo de salud del servicio
- ✅ **CloudWatch Logs**: Logs centralizados
- ✅ **IAM Roles**: Permisos seguros

### Endpoints Disponibles:

```
GET  /api/scheduling/health              - Health check
GET  /api/scheduling/info                - Información de la API
GET  /api/scheduling/appointments        - Listar citas
POST /api/scheduling/appointments        - Crear cita
GET  /api/scheduling/appointments/:id    - Obtener cita específica
PUT  /api/scheduling/appointments/:id    - Actualizar cita
DELETE /api/scheduling/appointments/:id  - Eliminar cita
GET  /api/scheduling/available-slots     - Horarios disponibles
GET  /api/scheduling/statistics          - Estadísticas
```

## 🏗️ Arquitectura

- **Flask API** en Python
- **Gunicorn** con 4 workers
- **Auto Scaling Group** (2-4 instancias)
- **MySQL/RDS** para persistencia
- **CloudWatch** para logs y métricas
- **Security Group** dedicado (puerto 8000)

## 📊 Auto Scaling

- **Scale Up**: CPU > 75% por 2 minutos
- **Scale Down**: CPU < 25% por 2 minutos
- **Cooldown**: 5 minutos

## 🔒 Seguridad

- Instancias en subnets privadas
- Solo accesible desde ALB/App servers
- IAM roles con mínimos permisos
- Credenciales de BD vía variables

## 💾 Base de Datos

Tabla `appointments`:
- id, client_name, client_email
- appointment_date, service_type
- status (pending/confirmed/cancelled)
- notes, created_at, updated_at

## 📝 Ejemplo de Uso

### Crear una cita:
```bash
curl -X POST http://your-alb/api/scheduling/appointments \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Juan Pérez",
    "client_email": "juan@example.com",
    "appointment_date": "2025-12-15T10:00:00",
    "service_type": "Consulta",
    "notes": "Primera visita"
  }'
```

### Consultar horarios disponibles:
```bash
curl http://your-alb/api/scheduling/available-slots?date=2025-12-15
```

## 🔧 Variables de Configuración

Ver `variables.tf` para todas las opciones de configuración.
