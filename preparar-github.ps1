# Script para preparar y subir el proyecto a GitHub

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PREPARAR REPO PARA GITHUB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. VERIFICAR GIT
Write-Host "[1/6] Verificando Git..." -ForegroundColor Green
$gitVersion = git --version 2>$null
if ($gitVersion) {
    Write-Host "✅ Git instalado: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Git no está instalado. Instálalo desde: https://git-scm.com/" -ForegroundColor Red
    exit
}
Write-Host ""

# 2. LIMPIAR ARCHIVOS SENSIBLES
Write-Host "[2/6] Limpiando archivos sensibles..." -ForegroundColor Green

# Eliminar archivos que no deben subirse
$filesToRemove = @(
    "terraform.tfstate*",
    ".terraform/",
    "*.tfvars",
    "plan-output.txt",
    "outputs.json",
    "resumen-despliegue.txt",
    "current-state.txt",
    "resources-list.txt",
    "graph.dot",
    "Examen*.pdf"
)

foreach ($pattern in $filesToRemove) {
    Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}

Write-Host "✅ Archivos sensibles eliminados" -ForegroundColor Green
Write-Host ""

# 3. PREPARAR README
Write-Host "[3/6] Preparando README..." -ForegroundColor Green
if (Test-Path "README_GITHUB.md") {
    if (Test-Path "README.md") {
        Move-Item "README.md" "README_ORIGINAL.md" -Force
    }
    Move-Item "README_GITHUB.md" "README.md" -Force
    Write-Host "✅ README actualizado para GitHub" -ForegroundColor Green
} else {
    Write-Host "⚠️  README_GITHUB.md no encontrado" -ForegroundColor Yellow
}
Write-Host ""

# 4. INICIALIZAR REPOSITORIO
Write-Host "[4/6] Inicializando repositorio Git..." -ForegroundColor Green

if (Test-Path ".git") {
    Write-Host "⚠️  Repositorio Git ya existe" -ForegroundColor Yellow
    $reinit = Read-Host "¿Reinicializar repositorio? (S/N)"
    if ($reinit -eq "S") {
        Remove-Item -Path ".git" -Recurse -Force
        git init
        Write-Host "✅ Repositorio reinicializado" -ForegroundColor Green
    }
} else {
    git init
    Write-Host "✅ Repositorio Git inicializado" -ForegroundColor Green
}
Write-Host ""

# 5. CONFIGURAR USUARIO GIT
Write-Host "[5/6] Configuración de Git..." -ForegroundColor Green
Write-Host "Ingresa tus datos de GitHub:" -ForegroundColor White
$userName = Read-Host "Nombre de usuario"
$userEmail = Read-Host "Email"

git config user.name "$userName"
git config user.email "$userEmail"
Write-Host "✅ Usuario configurado" -ForegroundColor Green
Write-Host ""

# 6. PREPARAR COMMIT INICIAL
Write-Host "[6/6] Preparando commit inicial..." -ForegroundColor Green

# Agregar todos los archivos
git add .

# Crear commit
git commit -m "Initial commit: Infraestructura de red empresarial con Terraform

- Módulo de red (VPC, Subnets, Gateways, Security Groups)
- Módulo de compute (Web, API, Database)
- Arquitectura de 3 capas con alta disponibilidad
- Auto Scaling y Load Balancing
- Documentación completa y scripts de demostración"

Write-Host "✅ Commit inicial creado" -ForegroundColor Green
Write-Host ""

# INSTRUCCIONES FINALES
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SIGUIENTES PASOS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Crea un repositorio público en GitHub:" -ForegroundColor Yellow
Write-Host "   https://github.com/new" -ForegroundColor White
Write-Host ""

Write-Host "2. Copia el nombre del repo (ej: examen-redes-terraform)" -ForegroundColor Yellow
Write-Host ""

$repoName = Read-Host "Ingresa el nombre del repositorio creado"

if ($repoName) {
    Write-Host ""
    Write-Host "3. Ejecuta estos comandos:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   git branch -M main" -ForegroundColor Cyan
    Write-Host "   git remote add origin https://github.com/$userName/$repoName.git" -ForegroundColor Cyan
    Write-Host "   git push -u origin main" -ForegroundColor Cyan
    Write-Host ""
    
    $executeNow = Read-Host "¿Ejecutar estos comandos ahora? (S/N)"
    
    if ($executeNow -eq "S") {
        Write-Host ""
        Write-Host "Configurando y subiendo a GitHub..." -ForegroundColor Green
        
        git branch -M main
        git remote add origin "https://github.com/$userName/$repoName.git"
        git push -u origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "  ✅ REPOSITORIO SUBIDO EXITOSAMENTE" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Tu repositorio está disponible en:" -ForegroundColor White
            Write-Host "https://github.com/$userName/$repoName" -ForegroundColor Cyan
            Write-Host ""
            
            $openRepo = Read-Host "¿Abrir repositorio en navegador? (S/N)"
            if ($openRepo -eq "S") {
                Start-Process "https://github.com/$userName/$repoName"
            }
        } else {
            Write-Host ""
            Write-Host "❌ Error al subir el repositorio" -ForegroundColor Red
            Write-Host "Verifica tus credenciales de GitHub" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ARCHIVOS PREPARADOS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Archivos en el repositorio:" -ForegroundColor White
git ls-files | ForEach-Object { Write-Host "  + $_" -ForegroundColor Gray }
Write-Host ""

Write-Host "Para hacer cambios futuros:" -ForegroundColor Yellow
Write-Host "  1. git add ." -ForegroundColor Gray
Write-Host "  2. git commit -m 'Descripcion del cambio'" -ForegroundColor Gray
Write-Host "  3. git push" -ForegroundColor Gray
Write-Host ""

Write-Host "Repositorio listo!" -ForegroundColor Green
