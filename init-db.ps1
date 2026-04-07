$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$initSql = Join-Path $projectRoot "backend\src\main\resources\db\init_all.sql"

if (!(Test-Path $initSql)) {
  throw "Init SQL not found: $initSql"
}

$mysqlCmd = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysqlCmd) {
  throw "mysql command not found. Install MySQL client and add it to PATH, then rerun."
}

Write-Host "Using mysql: $($mysqlCmd.Source)" -ForegroundColor Cyan
Write-Host "Initializing database community_service..." -ForegroundColor Green

Push-Location $projectRoot
try {
  # -p asks password interactively for safety
  & mysql -u root -p < $initSql
  Write-Host "Database initialized successfully." -ForegroundColor Green
} finally {
  Pop-Location
}
