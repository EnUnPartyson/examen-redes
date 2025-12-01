# Script PowerShell para Demostración Automática

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DEMOSTRACIÓN - EXAMEN REDES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Función para pausar y mostrar mensaje
function Pause-Demo {
    param([string]$Message)
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Yellow
    Write-Host "Presiona Enter para continuar..." -ForegroundColor Gray
    Read-Host
}

# 1. VERIFICAR PREREQUISITOS
Write-Host "[1/8] Verificando prerequisitos..." -ForegroundColor Green
Write-Host ""

Write-Host "Versión de Terraform:" -ForegroundColor White
terraform version
Write-Host ""

Write-Host "Identidad AWS:" -ForegroundColor White
aws sts get-caller-identity
Write-Host ""

Pause-Demo "Prerequisitos verificados"

# 2. MOSTRAR ESTRUCTURA DEL PROYECTO
Write-Host "[2/8] Estructura del proyecto..." -ForegroundColor Green
Get-ChildItem -Recurse -Directory | Select-Object FullName
Write-Host ""
Write-Host "Archivos Terraform:"
Get-ChildItem -Recurse -Filter "*.tf" | Select-Object FullName, Length
Write-Host ""

Pause-Demo "Estructura mostrada"

# 3. INICIALIZAR TERRAFORM
Write-Host "[3/8] Inicializando Terraform..." -ForegroundColor Green
terraform init
Write-Host ""

Pause-Demo "Terraform inicializado"

# 4. VALIDAR CONFIGURACIÓN
Write-Host "[4/8] Validando configuración..." -ForegroundColor Green
terraform validate
Write-Host ""

Write-Host "Verificando formato:" -ForegroundColor White
terraform fmt -check -recursive
Write-Host ""

Pause-Demo "Configuración validada"

# 5. GENERAR PLAN
Write-Host "[5/8] Generando plan de ejecución..." -ForegroundColor Green
Write-Host "Esto puede tomar 1-2 minutos..." -ForegroundColor Gray
terraform plan -out=tfplan

# Guardar plan en archivo
terraform show tfplan > plan-output.txt
Write-Host ""
Write-Host "✅ Plan guardado en: plan-output.txt" -ForegroundColor Green
Write-Host ""

Pause-Demo "Plan generado"

# 6. MOSTRAR RECURSOS A CREAR
Write-Host "[6/8] Analizando recursos del plan..." -ForegroundColor Green
$planContent = Get-Content plan-output.txt -Raw

# Contar recursos
if ($planContent -match "Plan: (\d+) to add") {
    $toAdd = $matches[1]
    Write-Host "Recursos a crear: $toAdd" -ForegroundColor Cyan
}

# Mostrar algunos recursos clave
Write-Host ""
Write-Host "Recursos principales a crear:" -ForegroundColor White
Write-Host "  • VPC y Redes" -ForegroundColor Yellow
Write-Host "  • Internet Gateway" -ForegroundColor Yellow
Write-Host "  • NAT Gateways (2)" -ForegroundColor Yellow
Write-Host "  • Subnets Públicas (2)" -ForegroundColor Yellow
Write-Host "  • Subnets Privadas (2)" -ForegroundColor Yellow
Write-Host "  • Security Groups (4)" -ForegroundColor Yellow
Write-Host "  • Application Load Balancer" -ForegroundColor Yellow
Write-Host "  • Auto Scaling Groups (2)" -ForegroundColor Yellow
Write-Host "  • Instancias EC2 (4+)" -ForegroundColor Yellow
Write-Host "  • Base de Datos RDS MySQL" -ForegroundColor Yellow
Write-Host ""

Pause-Demo "Recursos analizados"

# 7. PREGUNTAR SI APLICAR
Write-Host "[7/8] ¿Deseas aplicar la infraestructura?" -ForegroundColor Green
Write-Host "ADVERTENCIA: Esto creará recursos reales en AWS y puede generar costos" -ForegroundColor Red
Write-Host ""
$apply = Read-Host "Escribe 'SI' para aplicar o Enter para omitir"

if ($apply -eq "SI") {
    Write-Host ""
    Write-Host "Aplicando infraestructura..." -ForegroundColor Green
    Write-Host "Tiempo estimado: 10-15 minutos" -ForegroundColor Gray
    Write-Host ""
    
    terraform apply tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Infraestructura desplegada exitosamente!" -ForegroundColor Green
        Write-Host ""
        
        # 8. MOSTRAR OUTPUTS
        Write-Host "[8/8] Outputs de la infraestructura..." -ForegroundColor Green
        Write-Host ""
        terraform output
        Write-Host ""
        
        # Guardar outputs
        terraform output -json > outputs.json
        Write-Host "✅ Outputs guardados en: outputs.json" -ForegroundColor Green
        Write-Host ""
        
        # Obtener URL de la aplicación
        $appUrl = terraform output -raw application_url 2>$null
        if ($appUrl) {
            Write-Host "🌐 URL de la aplicación: $appUrl" -ForegroundColor Cyan
            Write-Host ""
            $openBrowser = Read-Host "¿Abrir en navegador? (S/N)"
            if ($openBrowser -eq "S") {
                Start-Process $appUrl
            }
        }
        
        # Crear resumen
        $summary = @"
INFRAESTRUCTURA DESPLEGADA
==========================
Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Proyecto: Examen Redes de Computadores

RECURSOS CREADOS:
$(terraform state list)

OUTPUTS:
$(terraform output)

ESTADO: COMPLETADO ✅
"@
        $summary | Out-File -Encoding utf8 "resumen-despliegue.txt"
        Write-Host "✅ Resumen guardado en: resumen-despliegue.txt" -ForegroundColor Green
        
    } else {
        Write-Host ""
        Write-Host "❌ Error al aplicar infraestructura" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "⏭️  Aplicación omitida" -ForegroundColor Yellow
    Write-Host "   Puedes aplicar manualmente con: terraform apply tfplan" -ForegroundColor Gray
}

# VERIFICACIÓN DE RECURSOS (si ya están desplegados)
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   VERIFICACIÓN DE RECURSOS AWS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$verify = Read-Host "¿Verificar recursos en AWS? (S/N)"
if ($verify -eq "S") {
    Write-Host ""
    Write-Host "Verificando VPCs..." -ForegroundColor Green
    aws ec2 describe-vpcs --filters "Name=tag:Project,Values=Examen Redes de Computadores" --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table
    Write-Host ""
    
    Write-Host "Verificando Instancias EC2..." -ForegroundColor Green
    aws ec2 describe-instances --filters "Name=tag:Project,Values=Examen Redes de Computadores" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PrivateIpAddress]' --output table
    Write-Host ""
    
    Write-Host "Verificando Load Balancers..." -ForegroundColor Green
    aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `examen`)].{Name:LoadBalancerName, DNS:DNSName, State:State.Code}' --output table
    Write-Host ""
    
    Write-Host "Verificando Base de Datos RDS..." -ForegroundColor Green
    aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `examen`)].{ID:DBInstanceIdentifier, Engine:Engine, Status:DBInstanceStatus, Endpoint:Endpoint.Address}' --output table
    Write-Host ""
}

# RESUMEN FINAL
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DEMOSTRACIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivos generados:" -ForegroundColor White
Write-Host "  • plan-output.txt - Plan de Terraform" -ForegroundColor Gray
Write-Host "  • outputs.json - Outputs en formato JSON" -ForegroundColor Gray
Write-Host "  • resumen-despliegue.txt - Resumen completo" -ForegroundColor Gray
Write-Host ""
Write-Host "Para destruir la infraestructura:" -ForegroundColor Yellow
Write-Host "  terraform destroy" -ForegroundColor Gray
Write-Host ""
Write-Host "¡Presentación lista! 🎓" -ForegroundColor Green
Write-Host ""
