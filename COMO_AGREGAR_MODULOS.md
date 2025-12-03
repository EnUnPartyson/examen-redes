# 🔧 Guía para Integrar Nuevos Módulos

Esta guía te muestra cómo agregar módulos adicionales a la infraestructura.

---

## 📝 Pasos para Integrar un Nuevo Módulo

### 1️⃣ Crear la Estructura del Módulo

```
modules/
└── tu-nuevo-modulo/
    ├── main.tf           # Recursos principales
    ├── variables.tf      # Variables de entrada
    ├── outputs.tf        # Outputs del módulo
    ├── user-data.sh      # Script de inicialización (opcional)
    └── README.md         # Documentación
```

### 2️⃣ Definir Variables (`variables.tf`)

```hcl
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID donde se desplegará"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de subnet IDs"
  type        = list(string)
}

# ... más variables según necesidad
```

### 3️⃣ Crear Recursos (`main.tf`)

```hcl
# Security Group
resource "aws_security_group" "module" {
  name_prefix = "${var.project_name}-${var.environment}-module-"
  description = "Security group for module"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-module-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Launch Template
resource "aws_launch_template" "module" {
  name_prefix   = "${var.project_name}-${var.environment}-module-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.module.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    # variables para el script
  }))

  # ... más configuración
}

# Auto Scaling Group
resource "aws_autoscaling_group" "module" {
  name                = "${var.project_name}-${var.environment}-module-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.module.id
    version = "$Latest"
  }

  # ... más configuración
}
```

### 4️⃣ Definir Outputs (`outputs.tf`)

```hcl
output "security_group_id" {
  description = "ID of the module security group"
  value       = aws_security_group.module.id
}

output "asg_name" {
  description = "Name of the auto scaling group"
  value       = aws_autoscaling_group.module.name
}

# ... más outputs según necesidad
```

### 5️⃣ Integrar en el Main (`main.tf` raíz)

```hcl
module "tu_nuevo_modulo" {
  source = "./modules/tu-nuevo-modulo"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.private_subnet_ids
  
  # Conectar con otros módulos
  security_group_id = module.network.app_security_group_id
  db_endpoint       = module.compute.db_endpoint
  alb_listener_arn  = module.compute.alb_listener_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### 6️⃣ Agregar Outputs al Main (`outputs.tf` raíz)

```hcl
output "tu_modulo_url" {
  description = "URL del nuevo módulo"
  value       = "http://${module.compute.alb_dns_name}/tu-ruta"
}

output "tu_modulo_info" {
  description = "Información del módulo"
  value = {
    asg_name = module.tu_nuevo_modulo.asg_name
    sg_id    = module.tu_nuevo_modulo.security_group_id
  }
}
```

---

## 🎯 Ejemplos de Módulos Que Podrías Agregar

### 1. Módulo de Notificaciones
```
modules/notifications/
├── SNS Topics
├── Lambda Functions
├── Email/SMS integration
└── CloudWatch Events
```

### 2. Módulo de Caché
```
modules/cache/
├── ElastiCache Redis
├── Security Groups
└── Parameter Groups
```

### 3. Módulo de Storage/Files
```
modules/storage/
├── S3 Buckets
├── CloudFront CDN
└── IAM Policies
```

### 4. Módulo de Queue/Jobs
```
modules/queue/
├── SQS Queues
├── Lambda Consumers
└── Dead Letter Queues
```

### 5. Módulo de Monitoring
```
modules/monitoring/
├── CloudWatch Dashboards
├── Alarms
├── SNS Topics
└── Lambda for alerts
```

### 6. Módulo de Auth/Users
```
modules/auth/
├── Cognito User Pools
├── API Integration
└── Lambda Triggers
```

### 7. Módulo de Analytics
```
modules/analytics/
├── Kinesis Streams
├── Lambda Processors
├── S3 Data Lake
└── Athena Queries
```

### 8. Módulo de Backup
```
modules/backup/
├── AWS Backup Plans
├── Vault Configuration
└── Lifecycle Policies
```

---

## 🔗 Dependencias Entre Módulos

### Patrón de Red Base
```
network → compute → scheduling-api
   ↓         ↓          ↓
  VPC      ALB      Integración
```

### Agregar Módulo Dependiente
```hcl
module "cache" {
  source = "./modules/cache"
  
  # Depende de network
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
  
  # Depende de compute
  app_security_group_id = module.compute.app_asg_security_group_id
}

module "queue" {
  source = "./modules/queue"
  
  # Depende de cache
  cache_endpoint = module.cache.redis_endpoint
}
```

---

## ✅ Checklist de Integración

- [ ] Crear directorio `modules/nuevo-modulo/`
- [ ] Definir `variables.tf` con todas las entradas
- [ ] Implementar `main.tf` con recursos AWS
- [ ] Crear `outputs.tf` para exponer información
- [ ] Escribir `user-data.sh` si necesita inicialización
- [ ] Agregar documentación en `README.md`
- [ ] Integrar en `main.tf` raíz
- [ ] Agregar outputs relevantes
- [ ] Actualizar README principal
- [ ] Ejecutar `terraform init`
- [ ] Ejecutar `terraform validate`
- [ ] Ejecutar `terraform plan`
- [ ] Revisar el plan de ejecución
- [ ] Ejecutar `terraform apply`
- [ ] Verificar recursos creados
- [ ] Probar funcionalidad
- [ ] Documentar endpoints/accesos

---

## 🧪 Testing del Nuevo Módulo

```bash
# 1. Inicializar
terraform init

# 2. Validar sintaxis
terraform validate

# 3. Ver plan
terraform plan

# 4. Aplicar solo el módulo (si es posible)
terraform apply -target=module.tu_nuevo_modulo

# 5. Verificar outputs
terraform output

# 6. Verificar en AWS Console
aws <servicio> describe-<recursos> --filters "Name=tag:Project,Values=..."
```

---

## 🎓 Mejores Prácticas

1. **Modularidad**: Un módulo = Un propósito específico
2. **Variables**: Usa variables para todo lo configurable
3. **Outputs**: Expone solo información necesaria
4. **Nombres**: Usa prefijos consistentes (project-env-service)
5. **Tags**: Etiqueta TODOS los recursos
6. **Seguridad**: Security Groups específicos por servicio
7. **Documentación**: README.md en cada módulo
8. **Versiones**: Usa `required_version` en providers
9. **State**: Siempre usa remote state en producción
10. **Testing**: Valida antes de aplicar

---

## 📚 Recursos Adicionales

- [Terraform Module Documentation](https://www.terraform.io/docs/modules/index.html)
- [AWS Provider Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Well-Architected](https://aws.amazon.com/architecture/well-architected/)

---

## 💡 Ejemplo Completo: Módulo de Notificaciones

Ver `modules/scheduling-api/` como referencia de implementación completa.

Características que implementa:
- ✅ Security Groups específicos
- ✅ Auto Scaling con políticas
- ✅ CloudWatch Logs
- ✅ IAM Roles y Policies
- ✅ Health Checks
- ✅ Integración con ALB
- ✅ Integración con RDS
- ✅ User Data para inicialización
- ✅ Outputs completos
- ✅ Documentación detallada
