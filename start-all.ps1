$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $projectRoot "frontend"
$backendDir = Join-Path $projectRoot "backend"
$mavenCmd = Join-Path $projectRoot "tools\apache-maven-3.9.9\bin\mvn.cmd"
$javaHome = "C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"
$pnpmCmd = Join-Path $env:APPDATA "npm\pnpm.cmd"

if (!(Test-Path $frontendDir)) { throw "frontend directory not found: $frontendDir" }
if (!(Test-Path $backendDir)) { throw "backend directory not found: $backendDir" }
if (!(Test-Path $mavenCmd)) { throw "Maven not found: $mavenCmd" }
if (!(Test-Path $javaHome)) { throw "JDK not found: $javaHome" }
if (!(Test-Path $pnpmCmd)) { throw "pnpm not found: $pnpmCmd. Run npm i -g pnpm first." }

function Stop-PortProcess {
  param([int]$Port)

  $pattern = ':{0}\s+.*LISTENING\s+(\d+)$' -f $Port
  $lines = netstat -ano | Select-String $pattern
  if (!$lines) { return }

  $pids = @()
  foreach ($line in $lines) {
    if ($line.Matches.Count -gt 0) {
      $pids += [int]$line.Matches[0].Groups[1].Value
    }
  }

  $pids = $pids | Select-Object -Unique
  foreach ($procId in $pids) {
    if ($procId -eq 0 -or $procId -eq 4) { continue }
    try {
      Stop-Process -Id $procId -Force -ErrorAction Stop
      Write-Host "Released port $Port, killed PID=$procId" -ForegroundColor Yellow
    } catch {
      Write-Host "Failed to kill PID=$procId on port $Port. Try running as Administrator." -ForegroundColor Red
    }
  }
}

Write-Host "Cleaning occupied ports..." -ForegroundColor Green
Stop-PortProcess -Port 8080
Stop-PortProcess -Port 7000

Write-Host "Starting backend and frontend..." -ForegroundColor Green

$backendCommand = @"
`$env:JAVA_HOME='$javaHome'
Set-Location '$backendDir'
& '$mavenCmd' spring-boot:run
"@

$frontendCommand = @"
`$env:CI='true'
Set-Location '$frontendDir'
& '$pnpmCmd' run dev
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCommand
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCommand

Write-Host "Launch commands have been sent:" -ForegroundColor Cyan
Write-Host "- Backend: http://localhost:8080" -ForegroundColor Cyan
Write-Host "- Frontend: http://localhost:7000" -ForegroundColor Cyan
