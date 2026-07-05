#Requires -Version 5.1
# Guido — instalador para Windows. PUBLIC bootstrap artifact (spec 2026-07-04 §7): thin —
# prereqs + gh login + clone, then DELEGATES to the cloned repo's install.ps1 -Managed.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$UserHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
$Src = if ($env:GUIDO_SRC) { $env:GUIDO_SRC } else { Join-Path $UserHome ".guido\src" }
$RepoUrl = if ($env:GUIDO_REPO_URL) { $env:GUIDO_REPO_URL } else { "https://github.com/Sk-Proyects/guido-cortex" }

function Say($m) { Write-Output ">> $m" }
function Die($m) { [Console]::Error.WriteLine("ERROR: $m"); Read-Host "presiona Enter para cerrar" | Out-Null; exit 1 }

Write-Output ""
Write-Output "  Hola — vamos a instalar Guido. Te va a pedir un par de logins en el navegador."
Write-Output ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Die "winget no está disponible — instala 'App Installer' desde la Microsoft Store y vuelve a correr esto."
}
$WingetFlags = @("--silent", "--accept-source-agreements", "--accept-package-agreements")

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Say "instalando git..."
  & winget install -e --id Git.Git @WingetFlags
  if ($LASTEXITCODE -ne 0) { Die "no pude instalar git — revisa tu conexión y vuelve a correr esto" }
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Say "instalando GitHub CLI..."
  & winget install -e --id GitHub.cli @WingetFlags
  if ($LASTEXITCODE -ne 0) { Die "no pude instalar GitHub CLI — revisa tu conexión y vuelve a correr esto" }
}
# fresh installs may not be on PATH in THIS session — probe common locations
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path

& gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
  Say "inicia sesión en GitHub (se abre el navegador)..."
  & gh auth login --hostname github.com --git-protocol https --web
  if ($LASTEXITCODE -ne 0) { Die "no pude conectar GitHub" }
}
& gh auth setup-git
if ($LASTEXITCODE -ne 0) { Die "no pude configurar git con tu cuenta de GitHub" }

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Say "instalando uv..."
  Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
  $env:Path = (Join-Path $UserHome ".local\bin") + ";" + $env:Path
}

if (-not (Test-Path (Join-Path $Src ".git"))) {
  Say "descargando Guido..."
  New-Item -ItemType Directory -Force -Path (Split-Path $Src -Parent) | Out-Null
  & git clone $RepoUrl $Src
  if ($LASTEXITCODE -ne 0) { Die "no pude descargar Guido — ¿tu cuenta tiene acceso?" }
}

& powershell -NoLogo -ExecutionPolicy Bypass -File (Join-Path $Src "scripts\install.ps1") -Managed -Yes
if ($LASTEXITCODE -ne 0) { Die "la instalación falló" }

Say "¡listo! Guido quedó en tu escritorio y menú inicio."
if ($env:GUIDO_BOOTSTRAP_NO_LAUNCH -eq "1") { exit 0 }
& powershell -NoLogo -ExecutionPolicy Bypass -File (Join-Path $UserHome ".guido\bin\guido-launch.ps1")
