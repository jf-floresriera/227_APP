<#
.SYNOPSIS
  Purdue Maize Disease Monitor - Script de desarrollo para Windows.

.DESCRIPTION
  Equivalente al Makefile para PowerShell.
  Uso: .\dev.ps1 <comando>

.EXAMPLE
  .\dev.ps1 up
  .\dev.ps1 migrate
  .\dev.ps1 seed
  .\dev.ps1 flutter-web
#>

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

# -- Helpers ------------------------------------------------------------------
function Write-Step  { param($msg) Write-Host "> $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# -- Comandos -----------------------------------------------------------------

function Show-Help {
    Write-Host ""
    Write-Host "  Purdue Maize Disease Monitor - comandos disponibles" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Backend (Docker):" -ForegroundColor White
    Write-Host "    .\dev.ps1 up             Levantar DB + API"
    Write-Host "    .\dev.ps1 down           Detener contenedores"
    Write-Host "    .\dev.ps1 migrate        Ejecutar migraciones Alembic"
    Write-Host "    .\dev.ps1 seed           Cargar datos demo"
    Write-Host "    .\dev.ps1 logs           Ver logs del API"
    Write-Host "    .\dev.ps1 status         Estado de los contenedores"
    Write-Host "    .\dev.ps1 api-shell      Shell dentro del contenedor API"
    Write-Host "    .\dev.ps1 reset          Eliminar volumenes y reiniciar"
    Write-Host ""
    Write-Host "  Flutter:" -ForegroundColor White
    Write-Host "    .\dev.ps1 build-runner   Generar archivos .g.dart"
    Write-Host "    .\dev.ps1 flutter-web    Correr la app en Chrome"
    Write-Host "    .\dev.ps1 flutter-android Correr en emulador Android"
    Write-Host ""
}

function Invoke-Up {
    Write-Step "Levantando base de datos..."
    docker compose up -d db
    if ($LASTEXITCODE -ne 0) { Write-Err "Fallo docker compose up db"; exit 1 }

    Write-Step "Esperando que PostgreSQL este listo (5 s)..."
    Start-Sleep -Seconds 5

    Write-Step "Levantando API y Adminer..."
    docker compose up -d api adminer
    if ($LASTEXITCODE -ne 0) { Write-Err "Fallo docker compose up api"; exit 1 }

    Write-OK "Stack levantado:"
    Write-Host "   API   ->  http://localhost:8000"
    Write-Host "   Docs  ->  http://localhost:8000/docs"
    Write-Host "   DB UI ->  http://localhost:8080"
    Write-Host ""
    Write-Host "  Proximo paso: .\dev.ps1 migrate" -ForegroundColor DarkCyan
}

function Invoke-Down {
    Write-Step "Deteniendo contenedores..."
    docker compose down
    Write-OK "Contenedores detenidos."
}

function Invoke-Status {
    docker compose ps
}

function Invoke-Logs {
    Write-Step "Mostrando logs del API (Ctrl+C para salir)..."
    docker compose logs -f api
}

function Invoke-ApiShell {
    Write-Step "Abriendo shell en el contenedor API..."
    docker compose exec api bash
}

function Invoke-Migrate {
    Write-Step "Ejecutando migraciones Alembic..."
    docker compose exec api alembic upgrade head
    if ($LASTEXITCODE -ne 0) { Write-Err "Las migraciones fallaron. Esta levantado el stack? (.\dev.ps1 up)"; exit 1 }
    Write-OK "Migraciones aplicadas correctamente."
    Write-Host "  Proximo paso: .\dev.ps1 seed" -ForegroundColor DarkCyan
}

function Invoke-Seed {
    Write-Step "Cargando datos demo..."
    docker compose exec api bash -c "cd /app && python -m scripts.seed_demo"
    if ($LASTEXITCODE -ne 0) { Write-Err "El seed fallo."; exit 1 }
    Write-OK "Datos demo cargados."
    Write-Host "   Email:    demo@purdue.edu"
    Write-Host "   Password: purdue2025"
    Write-Host "   Docs:     http://localhost:8000/docs"
}

function Invoke-Reset {
    Write-Warn "Esto eliminara TODOS los datos de la base de datos."
    $confirm = Read-Host "Estas seguro? (escribe 'si' para confirmar)"
    if ($confirm -eq "si") {
        docker compose down -v
        Write-OK "Reset completado. Usa .\dev.ps1 up para volver a levantar."
    } else {
        Write-Host "Cancelado."
    }
}

function Invoke-BuildRunner {
    Write-Step "Instalando paquetes Flutter..."
    Set-Location purdue_maize_app
    flutter pub get
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Write-Err "flutter pub get fallo"; exit 1 }

    Write-Step "Generando archivos .g.dart (Drift + Riverpod)..."
    flutter pub run build_runner build --delete-conflicting-outputs
    if ($LASTEXITCODE -ne 0) { Set-Location ..; Write-Err "build_runner fallo"; exit 1 }

    Set-Location ..
    Write-OK "Generacion completada. Ya puedes correr la app."
}

function Invoke-FlutterWeb {
    Write-Step "Iniciando app Flutter en Chrome..."
    Write-Host "   API base: http://localhost:8000/api/v1"
    Set-Location purdue_maize_app
    flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
    Set-Location ..
}

function Invoke-FlutterAndroid {
    Write-Step "Iniciando app Flutter en Android..."
    Write-Host "   API base: http://10.0.2.2:8000/api/v1 (emulador -> localhost)"
    Set-Location purdue_maize_app
    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
    Set-Location ..
}

# -- Dispatcher ---------------------------------------------------------------

switch ($Command.ToLower()) {
    "help"             { Show-Help }
    "up"               { Invoke-Up }
    "down"             { Invoke-Down }
    "status"           { Invoke-Status }
    "logs"             { Invoke-Logs }
    "api-shell"        { Invoke-ApiShell }
    "migrate"          { Invoke-Migrate }
    "seed"             { Invoke-Seed }
    "reset"            { Invoke-Reset }
    "build-runner"     { Invoke-BuildRunner }
    "flutter-web"      { Invoke-FlutterWeb }
    "flutter-android"  { Invoke-FlutterAndroid }
    default {
        Write-Err "Comando desconocido: '$Command'"
        Show-Help
        exit 1
    }
}
