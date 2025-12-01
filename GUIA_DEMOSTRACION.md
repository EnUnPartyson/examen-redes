# Guía de Demostración - Examen Redes de Computadores

## 📋 PREPARACIÓN ANTES DE LA PRESENTACIÓN

### 1. Verificar Prerequisitos
```powershell
# Verificar instalación de Terraform
terraform version

# Verificar credenciales AWS
aws sts get-caller-identity

# Verificar región configurada
aws configure get region
```

---

## 🚀 DEMOSTRACIÓN EN VIVO

### PASO 1: Inicializar Terraform
```powershell
cd "c:\Users\ariel\examen redes"

# Inicializar Terraform (descarga providers)
terraform init
```

**Captura de pantalla**: Mostrar inicialización exitosa

---

### PASO 2: Validar Configuración
```powershell
# Validar sintaxis de archivos Terraform
terraform validate

# Verificar formato del código
terraform fmt -check -recursive
```

**Captura de pantalla**: Validación exitosa

---

### PASO 3: Ver Plan de Ejecución
```powershell
# Generar y mostrar plan de infraestructura
terraform plan -out=tfplan

# Guardar plan en formato legible
terraform show tfplan > plan-output.txt
```

**Qué mostrar**:
- Número total de recursos a crear (≈50-60 recursos)
- Recursos principales: VPC, Subnets, EC2, RDS, ALB
- Sin errores en el plan

**Captura de pantalla**: Plan detallado

---

### PASO 4: Aplicar Infraestructura
```powershell
# Desplegar toda la infraestructura
terraform apply tfplan

# O con confirmación manual:
# terraform apply
```

**Tiempo estimado**: 10-15 minutos

**Captura de pantalla**: Apply en progreso y completado

---

### PASO 5: Obtener Outputs
```powershell
# Mostrar todos los outputs
terraform output

# Output específico de la URL de la aplicación
terraform output application_url

# Ver en formato JSON
terraform output -json > outputs.json
```

**Qué mostrar**:
- URL de la aplicación web
- IDs de recursos creados
- Endpoints de servicios

---

## 🔍 VERIFICACIÓN DE COMPONENTES

### 1. Verificar VPC y Redes
```powershell
# Listar VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=Examen Redes de Computadores" --output table

# Listar Subnets
aws ec2 describe-subnets --filters "Name=tag:Project,Values=Examen Redes de Computadores" --output table

# Verificar Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=Examen Redes de Computadores" --output table

# Verificar NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=Examen Redes de Computadores" --output table
```

**Capturas de pantalla**: Recursos de red creados

---

### 2. Verificar Security Groups
```powershell
# Listar Security Groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=Examen Redes de Computadores" --output table

# Ver reglas de un Security Group específico (Web)
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=*web*" --output json | ConvertFrom-Json | Select-Object -ExpandProperty SecurityGroups | Select-Object GroupId, GroupName, @{Name='InboundRules';Expression={$_.IpPermissions}}
```

**Qué mostrar**: 
- Security Groups Web, App, DB
- Reglas de entrada/salida configuradas

---

### 3. Verificar Instancias EC2
```powershell
# Listar todas las instancias
aws ec2 describe-instances --filters "Name=tag:Project,Values=Examen Redes de Computadores" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0],PrivateIpAddress]' --output table

# Ver Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `examen`)].{Name:AutoScalingGroupName, Min:MinSize, Max:MaxSize, Desired:DesiredCapacity, Instances:length(Instances)}' --output table
```

**Qué mostrar**:
- Instancias Web corriendo
- Instancias App corriendo
- Auto Scaling configurado

---

### 4. Verificar Load Balancer
```powershell
# Listar Load Balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `examen`)].{Name:LoadBalancerName, DNS:DNSName, State:State.Code, Type:Type}' --output table

# Ver Target Groups y salud de instancias
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw web_target_group_arn) --output table
```

**Qué mostrar**:
- ALB activo y funcionando
- Targets saludables (healthy)

---

### 5. Verificar Base de Datos RDS
```powershell
# Listar instancias RDS
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `examen`)].{ID:DBInstanceIdentifier, Engine:Engine, Status:DBInstanceStatus, Endpoint:Endpoint.Address, AZ:AvailabilityZone}' --output table

# Ver detalles de la base de datos
terraform output database_endpoint
```

**Qué mostrar**:
- RDS MySQL disponible
- Estado: Available
- Endpoint accesible

---

## 🌐 PRUEBAS FUNCIONALES

### 1. Probar Aplicación Web
```powershell
# Obtener URL de la aplicación
$APP_URL = terraform output -raw application_url
Write-Host "URL de la aplicación: $APP_URL"

# Abrir en navegador
Start-Process $APP_URL

# Probar con curl/Invoke-WebRequest
Invoke-WebRequest -Uri $APP_URL -Method GET
```

**Qué mostrar**:
- Página web cargando correctamente
- Información del servidor mostrada
- HTML renderizado

**Captura de pantalla**: Navegador mostrando la aplicación

---

### 2. Probar API (desde una instancia con acceso)
```powershell
# Nota: La API está en subnet privada, necesitas hacer esto desde una instancia web o con bastion
# Ejemplo de comando que ejecutarías:
# curl http://<app-server-ip>:8080/api/health
# curl http://<app-server-ip>:8080/api/info
```

---

### 3. Verificar Conectividad de Base de Datos
```powershell
# Obtener endpoint de la base de datos
$DB_ENDPOINT = terraform output -raw database_endpoint
Write-Host "Base de datos disponible en: $DB_ENDPOINT"

# Verificar que el puerto 3306 es accesible desde App Servers
# (Esto requiere estar dentro de la VPC)
```

---

## 📊 DIAGRAMAS Y VISUALIZACIONES

### 1. Generar Diagrama de Terraform
```powershell
# Generar gráfico de recursos (requiere Graphviz)
terraform graph | Out-File -Encoding utf8 graph.dot

# Convertir a imagen (si tienes Graphviz instalado)
# dot -Tpng graph.dot -o architecture-diagram.png
```

---

### 2. Capturar Estado Actual
```powershell
# Ver estado completo
terraform show > current-state.txt

# Listar todos los recursos
terraform state list > resources-list.txt

# Contar recursos
$resourceCount = (terraform state list).Count
Write-Host "Total de recursos desplegados: $resourceCount"
```

---

## 📸 CAPTURAS DE PANTALLA RECOMENDADAS

### Para la Presentación:

1. **AWS Console - VPC Dashboard**
   - Mostrar VPC creada
   - Subnets públicas y privadas
   - Route tables

2. **AWS Console - EC2 Dashboard**
   - Instancias corriendo
   - Load Balancer activo
   - Auto Scaling Groups

3. **AWS Console - RDS Dashboard**
   - Base de datos MySQL activa
   - Estado: Available

4. **Terminal - Comandos Terraform**
   - `terraform plan`
   - `terraform apply`
   - `terraform output`

5. **Navegador Web**
   - Aplicación web funcionando
   - Mostrar la página HTML

6. **Arquitectura Diagram**
   - Diagrama visual de la infraestructura

---

## 🎬 SCRIPT DE PRESENTACIÓN

### Introducción (2 min)
```
"Hoy presentaré una infraestructura de red empresarial completa 
implementada con Terraform en AWS, cumpliendo todos los requisitos 
del examen de Redes de Computadores."
```

### Demostración de Código (3 min)
```
1. Mostrar estructura de módulos
2. Explicar módulo de red (VPC, subnets, gateways)
3. Explicar módulo de compute (servidores, API, DB)
```

### Ejecución en Vivo (5 min)
```
1. terraform validate
2. terraform plan (mostrar recursos)
3. terraform apply (si el tiempo permite)
   O mostrar ejecución pre-grabada
```

### Verificación de Recursos (5 min)
```
1. Mostrar AWS Console con recursos creados
2. Ejecutar comandos AWS CLI
3. Mostrar outputs de Terraform
```

### Prueba Funcional (3 min)
```
1. Abrir URL de la aplicación
2. Mostrar página web funcionando
3. Explicar flujo: Internet → ALB → Web → App → DB
```

### Arquitectura y Seguridad (2 min)
```
1. Mostrar diagrama de arquitectura
2. Explicar capas de seguridad
3. Resaltar alta disponibilidad
```

---

## 📦 ARCHIVOS PARA LA PRESENTACIÓN

### Crear Carpeta de Evidencias
```powershell
# Crear carpeta para evidencias
New-Item -ItemType Directory -Path ".\presentacion" -Force

# Copiar archivos importantes
Copy-Item "README.md" -Destination ".\presentacion\"
Copy-Item "main.tf" -Destination ".\presentacion\"

# Exportar outputs
terraform output -json > ".\presentacion\outputs.json"
terraform state list > ".\presentacion\recursos-desplegados.txt"

# Crear resumen
@"
INFRAESTRUCTURA DESPLEGADA
==========================
Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Proyecto: Examen Redes de Computadores

RECURSOS CREADOS:
- VPC: $(terraform output -raw vpc_id)
- URL Aplicación: $(terraform output -raw application_url)
- Total de recursos: $(terraform state list | Measure-Object | Select-Object -ExpandProperty Count)

ESTADO: COMPLETADO
"@ | Out-File -Encoding utf8 ".\presentacion\resumen.txt"

Write-Host "✅ Archivos de presentación listos en la carpeta 'presentacion'"
```

---

## 🔄 AL FINALIZAR LA PRESENTACIÓN

### Opcional: Destruir Infraestructura
```powershell
# Para evitar costos, destruir recursos después
terraform destroy -auto-approve

# O mantener activo para demostración posterior
```

---

## ✅ CHECKLIST DE DEMOSTRACIÓN

- [ ] Terraform instalado y funcionando
- [ ] AWS CLI configurado
- [ ] Credenciales AWS válidas
- [ ] Código validado sin errores
- [ ] Plan de Terraform generado
- [ ] Infraestructura desplegada
- [ ] Capturas de pantalla tomadas
- [ ] URL de aplicación accesible
- [ ] Documento de presentación preparado
- [ ] Tiempo estimado: 20 minutos

---

## 💡 TIPS PARA LA PRESENTACIÓN

1. **Si el tiempo es limitado**: Tener la infraestructura ya desplegada antes de presentar
2. **Grabación de respaldo**: Grabar el `terraform apply` por si hay problemas en vivo
3. **Plan B**: Tener capturas de pantalla de todos los pasos
4. **Demostrar conocimiento**: Explicar cada componente mientras lo muestras
5. **Preparar preguntas frecuentes**: 
   - ¿Por qué dos NAT Gateways? (Alta disponibilidad)
   - ¿Por qué subnets públicas y privadas? (Seguridad)
   - ¿Cómo escala el sistema? (Auto Scaling Groups)

---

**¡Buena suerte en tu presentación! 🎓**
