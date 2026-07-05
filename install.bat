@echo off
rem Guido — doble click para instalar (Windows). Downloads the real bootstrap from the
rem PUBLIC repo and runs it (a .bat can't carry the full logic; PowerShell can).
set "GUIDO_BOOTSTRAP_URL=https://raw.githubusercontent.com/Sk-Proyects/guido-install/main/install.ps1"
powershell -NoLogo -ExecutionPolicy Bypass -Command ^
  "& { $f = Join-Path $env:TEMP 'guido-bootstrap.ps1'; Invoke-RestMethod $env:GUIDO_BOOTSTRAP_URL -OutFile $f; & powershell -NoLogo -ExecutionPolicy Bypass -File $f }"
pause
