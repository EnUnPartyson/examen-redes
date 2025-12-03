# Examen - Redes de Computadores
## Infraestructura de Red Empresarial con Terraform

[![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> Implementación completa de una arquitectura de red empresarial de 3 capas en AWS usando Terraform como Infraestructura como Código (IaC).

---

## 📋 Descripción del Proyecto

Este proyecto implementa una infraestructura de red empresarial completa en AWS con:

- **Arquitectura de 3 capas** (Web, Aplicación, Base de Datos)
- **Alta disponibilidad** en múltiples zonas de disponibilidad
- **Auto-escalado** automático según demanda
- **Seguridad en profundidad** con Security Groups y NACLs
- **Balanceo de carga** con Application Load Balancer
- **Servicios funcionales**: Servidor Web, API REST, Base de Datos MySQL

---

## 🏗️ Arquitectura

```
Internet
    ↓
[Application Load Balancer]
    ↓
┌─────────────────────────────────────────┐
│        Capa Web (Subnets Públicas)      │
│  • Servidores Apache (Auto Scaling)     │
│  • Puertos: 80, 443                     │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│    Capa Aplicación (Subnets Privadas)   │
│  • API REST Flask (Auto Scaling)        │
│  • Puerto: 8080                         │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│      Capa Datos (Subnets Privadas)      │
│  • RDS MySQL 8.0                        │
│  • Puerto: 3306                         │
└─────────────────────────────────────────┘
```

---

## 🌐 Componentes de Red

### Infraestructura de Red (Módulo Network)

- **1 VPC** con CIDR 10.0.0.0/16
- **2 Subnets Públicas** (10.0.1.0/24, 10.0.2.0/24)
- **2 Subnets Privadas** (10.0.10.0/24, 10.0.11.0/24)
- **1 Internet Gateway** para acceso público
- **2 NAT Gateways** para alta disponibilidad
- **3 Tablas de Enrutamiento** (1 pública, 2 privadas)
- **4 Security Groups** (Default, Web, App, DB)
- **2 Network ACLs** (Public, Private)

### Servicios (Módulo Compute)

- **Application Load Balancer** con health checks
- **Auto Scaling Groups**:
  - Web: 2-4 instancias EC2
  - App: 2-4 instancias EC2
- **Servidores Web**: Apache con HTML
- **API REST**: Flask en Python (endpoints `/api/health`, `/api/info`)
- **Base de Datos**: RDS MySQL 8.0 con backups automáticos

### API de Agendamiento (Módulo Scheduling-API)

- **API REST completa** para gestión de citas/agendamiento
- **Auto Scaling Group**: 2-4 instancias dedicadas
- **Endpoints disponibles**:
  - `GET /api/scheduling/health` - Health check
  - `GET /api/scheduling/appointments` - Listar citas
  - `POST /api/scheduling/appointments` - Crear cita
  - `GET /api/scheduling/appointments/:id` - Obtener cita
  - `PUT /api/scheduling/appointments/:id` - Actualizar cita
  - `DELETE /api/scheduling/appointments/:id` - Eliminar cita
  - `GET /api/scheduling/available-slots` - Horarios disponibles
  - `GET /api/scheduling/statistics` - Estadísticas
- **Base de datos** integrada con RDS MySQL
- **CloudWatch Logs** para monitoreo
- **IAM Roles** con permisos específicos

---

## 📁 Estructura del Proyecto

```
examen-redes/
├── main.tf                    # Orquestación principal
├── provider.tf                # Configuración AWS
├── variables.tf               # Variables globales
├── outputs.tf                 # Outputs del sistema
├── README.md                  # Este archivo
├── GUIA_DEMOSTRACION.md       # Guía de demostración
├── demo.ps1                   # Script de demostración
├── terraform.tfvars.example   # Ejemplo de configuración
├── .gitignore                 # Archivos a ignorar
└── modules/
    ├── network/               # Módulo de infraestructura de red
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── compute/               # Módulo de servicios
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── scheduling-api/        # Módulo de API de Agendamiento
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── user-data.sh
        └── README.md
```

---

## 🚀 Inicio Rápido

### Prerequisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Cuenta de AWS con permisos de administrador
- Conocimientos básicos de Terraform y AWS

### Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/examen-redes.git
cd examen-redes
```

2. **Configurar credenciales AWS**
```bash
aws configure
```

3. **Inicializar Terraform**
```bash
terraform init
```

4. **Validar configuración**
```bash
terraform validate
```

5. **Revisar el plan**
```bash
terraform plan
```

6. **Desplegar infraestructura**
```bash
terraform apply
```

⏱️ **Tiempo de despliegue**: 10-15 minutos

7. **Obtener outputs**
```bash
terraform output
```

---

## 🔧 Configuración

### Variables Principales

Crea un archivo `terraform.tfvars` (basado en `terraform.tfvars.example`):

```hcl
aws_region   = "us-east-1"
project_name = "examen-redes"
environment  = "dev"
```

### Variables Opcionales

- `instance_type_web`: Tipo de instancia para web servers (default: `t2.micro`)
- `instance_type_app`: Tipo de instancia para app servers (default: `t2.micro`)
- `key_name`: Nombre del key pair SSH (opcional)

---

## 📊 Outputs

Después del despliegue obtendrás:

```bash
application_url      = "http://alb-xxxxxxxxx.us-east-1.elb.amazonaws.com"
scheduling_api_url   = "http://alb-xxxxxxxxx.us-east-1.elb.amazonaws.com/api/scheduling"
vpc_id              = "vpc-xxxxxxxxx"
database_endpoint   = "examen-redes-dev-db.xxxxxxxxx.us-east-1.rds.amazonaws.com:3306"
nat_gateway_ips     = ["54.xxx.xxx.xxx", "54.xxx.xxx.xxx"]
```

---

## 🚀 Uso de la API de Agendamiento

### Crear una cita

```bash
curl -X POST http://YOUR-ALB-URL/api/scheduling/appointments \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Juan Pérez",
    "client_email": "juan@example.com",
    "appointment_date": "2025-12-15T10:00:00",
    "service_type": "Consulta General",
    "notes": "Primera visita"
  }'
```

### Listar todas las citas

```bash
curl http://YOUR-ALB-URL/api/scheduling/appointments
```

### Consultar horarios disponibles

```bash
curl "http://YOUR-ALB-URL/api/scheduling/available-slots?date=2025-12-15"
```

### Ver estadísticas

```bash
curl http://YOUR-ALB-URL/api/scheduling/statistics
```

### Health check

```bash
curl http://YOUR-ALB-URL/api/scheduling/health
```

---

## 🧪 Verificación

### 1. Verificar Aplicación Web

Abre la URL del output `application_url` en tu navegador.

### 2. Verificar Recursos AWS

```bash
# Listar VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=Examen Redes de Computadores"

# Listar instancias
aws ec2 describe-instances --filters "Name=tag:Project,Values=Examen Redes de Computadores"

# Verificar Load Balancer
aws elbv2 describe-load-balancers

# Verificar RDS
aws rds describe-db-instances
```

### 3. Script de Demostración Automática

```powershell
.\demo.ps1
```

---

## 🔐 Seguridad

### Principios Implementados

✅ **Defensa en Profundidad**: 3 capas de seguridad  
✅ **Mínimo Privilegio**: Acceso restringido por capa  
✅ **Segregación de Red**: Subnets públicas/privadas  
✅ **Cifrado**: Tráfico HTTPS (configurable)  
✅ **Backups**: Automáticos en RDS  

### Security Groups

- **Web SG**: HTTP (80), HTTPS (443), SSH (desde VPC)
- **App SG**: Puerto 8080 (solo desde Web SG), SSH (desde VPC)
- **DB SG**: MySQL 3306 (solo desde App SG)

---

## 💰 Costos Estimados

| Recurso | Cantidad | Costo Mensual (aprox.) |
|---------|----------|------------------------|
| VPC, Subnets, IGW | - | Gratis |
| NAT Gateway | 2 | ~$65/mes |
| EC2 t2.micro | 4 | ~$30/mes |
| RDS db.t3.micro | 1 | ~$15/mes |
| ALB | 1 | ~$20/mes |
| **TOTAL** | - | **~$130/mes** |

💡 **Tip**: Destruye la infraestructura cuando no la uses para evitar costos.

---

## 🗑️ Limpieza

Para eliminar todos los recursos:

```bash
terraform destroy
```

⚠️ **Advertencia**: Esto eliminará TODOS los recursos creados.

---

## 📚 Documentación Adicional

- [Guía de Demostración](GUIA_DEMOSTRACION.md) - Paso a paso para demostrar el proyecto
- [Script de Demo](demo.ps1) - Script automatizado de demostración
- [Terraform Docs](https://www.terraform.io/docs)
- [AWS Best Practices](https://aws.amazon.com/architecture/well-architected/)

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📝 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 👨‍🎓 Autor

**Examen de Redes de Computadores**

- Proyecto: Infraestructura de Red Empresarial
- Tecnología: Terraform + AWS
- Año: 2025

---

## ⭐ Agradecimientos

- Documentación oficial de [Terraform](https://www.terraform.io/)
- Guías de [AWS](https://aws.amazon.com/)
- Comunidad de DevOps

---

## 📞 Contacto

Para preguntas o sugerencias sobre este proyecto, puedes abrir un [issue](../../issues) en GitHub.

---

**¡Desarrollado con ❤️ usando Terraform e Infraestructura como Código!**
