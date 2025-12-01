# Examen - Redes de Computadores
# Infraestructura de Red con Terraform

Este proyecto contiene la infraestructura de red implementada con Terraform para el examen de Redes de Computadores.

## Arquitectura de Red

La infraestructura incluye:

### VPC (Virtual Private Cloud)
- **CIDR:** 10.0.0.0/16
- DNS habilitado
- Soporte DNS habilitado

### Subnets Públicas
- **Subnet 1:** 10.0.1.0/24 (us-east-1a)
- **Subnet 2:** 10.0.2.0/24 (us-east-1b)
- Auto-asignación de IPs públicas habilitada
- Acceso directo a Internet mediante Internet Gateway

### Subnets Privadas
- **Subnet 1:** 10.0.10.0/24 (us-east-1a)
- **Subnet 2:** 10.0.11.0/24 (us-east-1b)
- Acceso a Internet mediante NAT Gateways
- Aisladas de acceso directo desde Internet

### Componentes de Red

#### Internet Gateway
- Permite comunicación entre recursos en subnets públicas e Internet

#### NAT Gateways
- Un NAT Gateway por zona de disponibilidad
- Permite que recursos en subnets privadas accedan a Internet
- No permite conexiones entrantes desde Internet

#### Route Tables
- **Tabla Pública:** Ruta 0.0.0.0/0 → Internet Gateway
- **Tablas Privadas:** Ruta 0.0.0.0/0 → NAT Gateway (una por AZ)

#### Network ACLs
- **Public NACL:** Permite todo el tráfico entrante y saliente
- **Private NACL:** Permite tráfico desde la VPC y todo el tráfico saliente

### Security Groups

#### Web Security Group
- **Puerto 80 (HTTP):** Desde 0.0.0.0/0
- **Puerto 443 (HTTPS):** Desde 0.0.0.0/0
- **Puerto 22 (SSH):** Solo desde la VPC (10.0.0.0/16)
- **Egress:** Todo el tráfico permitido

#### App Security Group
- **Puerto 8080:** Solo desde Web Security Group
- **Puerto 22 (SSH):** Solo desde la VPC (10.0.0.0/16)
- **Egress:** Todo el tráfico permitido

#### DB Security Group
- **Puerto 3306 (MySQL):** Solo desde App Security Group
- **Puerto 5432 (PostgreSQL):** Solo desde App Security Group
- **Egress:** Todo el tráfico permitido

## Estructura del Proyecto

```
examen-redes/
├── main.tf              # Configuración principal y uso del módulo
├── provider.tf          # Configuración del provider AWS
├── variables.tf         # Variables globales
├── outputs.tf           # Outputs principales
├── terraform.tfvars     # Valores de variables (crear localmente)
└── modules/
    └── network/
        ├── main.tf      # Recursos de red
        ├── variables.tf # Variables del módulo
        └── outputs.tf   # Outputs del módulo
```

## Requisitos Previos

1. **Terraform:** >= 1.0
2. **AWS CLI:** Configurado con credenciales válidas
3. **Provider AWS:** ~> 5.0

## Configuración

### 1. Clonar o navegar al directorio del proyecto

```bash
cd "c:\Users\ariel\examen redes"
```

### 2. Crear archivo terraform.tfvars (opcional)

```hcl
aws_region   = "us-east-1"
project_name = "examen-redes"
environment  = "dev"
```

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Validar la configuración

```bash
terraform validate
```

### 5. Ver el plan de ejecución

```bash
terraform plan
```

### 6. Aplicar la infraestructura

```bash
terraform apply
```

## Comandos Útiles

### Ver estado actual
```bash
terraform show
```

### Ver outputs
```bash
terraform output
```

### Ver recursos creados
```bash
terraform state list
```

### Destruir infraestructura
```bash
terraform destroy
```

## Outputs Disponibles

Después de aplicar la configuración, obtendrás:

- `vpc_id`: ID de la VPC creada
- `vpc_cidr`: Bloque CIDR de la VPC
- `public_subnet_ids`: IDs de las subnets públicas
- `private_subnet_ids`: IDs de las subnets privadas
- `nat_gateway_ips`: IPs elásticas de los NAT Gateways
- `web_security_group_id`: ID del security group web
- `app_security_group_id`: ID del security group de aplicación
- `db_security_group_id`: ID del security group de base de datos

## Personalización

### Cambiar el rango de IPs de la VPC

En `main.tf`, modifica:
```hcl
vpc_cidr = "10.0.0.0/16"  # Cambia a tu CIDR preferido
```

### Añadir más subnets

```hcl
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

### Deshabilitar NAT Gateway (para ahorrar costos)

```hcl
enable_nat_gateway = false
```

### Habilitar VPN Gateway

```hcl
enable_vpn_gateway = true
```

## Costos Estimados (AWS)

- **VPC:** Gratis
- **Subnets:** Gratis
- **Internet Gateway:** Gratis
- **NAT Gateway:** ~$0.045/hora + $0.045/GB procesado
- **Elastic IPs:** $0.005/hora (cuando no está asociada)
- **Security Groups:** Gratis
- **Route Tables:** Gratis

**Nota:** Los NAT Gateways son el componente más costoso. Para desarrollo/pruebas, considera deshabilitarlos.

## Seguridad

### Mejores Prácticas Implementadas

1. ✅ Separación de subnets públicas y privadas
2. ✅ Security Groups con principio de mínimo privilegio
3. ✅ NACLs configuradas
4. ✅ NAT Gateways para acceso seguro a Internet desde subnets privadas
5. ✅ SSH restringido a la VPC
6. ✅ Base de datos accesible solo desde capa de aplicación
7. ✅ Múltiples zonas de disponibilidad para alta disponibilidad

### Recomendaciones Adicionales

- Usar AWS Secrets Manager para credenciales de BD
- Implementar VPC Flow Logs para auditoría
- Configurar AWS WAF para aplicaciones web
- Habilitar GuardDuty para detección de amenazas
- Usar AWS Config para compliance

## Diagrama de Arquitectura

```
Internet
    |
    v
[Internet Gateway]
    |
    +------------------+------------------+
    |                                     |
[Public Subnet 1]              [Public Subnet 2]
10.0.1.0/24 (AZ-A)            10.0.2.0/24 (AZ-B)
    |                                     |
[NAT Gateway 1]                [NAT Gateway 2]
    |                                     |
    +------------------+------------------+
                       |
        +--------------+--------------+
        |                             |
[Private Subnet 1]         [Private Subnet 2]
10.0.10.0/24 (AZ-A)       10.0.11.0/24 (AZ-B)
```

## Troubleshooting

### Error: No credentials found
```bash
aws configure
```

### Error: Region not specified
Asegúrate de que `aws_region` esté configurada en `variables.tf` o `terraform.tfvars`

### Error: Subnet CIDR conflicts
Verifica que los bloques CIDR no se superpongan

## Licencia

Este proyecto es para fines educativos - Examen de Redes de Computadores.

## Autor

Estudiante - Examen Redes de Computadores 2025
