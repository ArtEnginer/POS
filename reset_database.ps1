# Quick Database Reset Script
# Use this to delete database and force recreation with new schema

param(
    [switch]$Force
)

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  DATABASE RESET UTILITY" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Find database file
$possiblePaths = @(
    "$env:LOCALAPPDATA\com.example.pos\pos_local.db",
    "$env:LOCALAPPDATA\pos\pos_local.db",
    "$env:LOCALAPPDATA\SuperPOS\pos_local.db"
)

$dbPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $dbPath = $path
        break
    }
}

if ($null -eq $dbPath) {
    Write-Host "❌ Database file not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checked locations:" -ForegroundColor Yellow
    foreach ($path in $possiblePaths) {
        Write-Host "  - $path"
    }
    Write-Host ""
    Write-Host "Note: Database only exists after first app run." -ForegroundColor Gray
    Write-Host "If app never ran, just run: flutter run -d windows" -ForegroundColor Green
    exit 1
}

Write-Host "✅ Found database:" -ForegroundColor Green
Write-Host "   $dbPath" -ForegroundColor Gray
Write-Host ""

# Check if app is running
$runningProcesses = Get-Process | Where-Object {
    $_.ProcessName -like "*pos*" -or 
    $_.ProcessName -like "*flutter*" -or
    $_.MainWindowTitle -like "*SuperPOS*"
}

if ($runningProcesses) {
    Write-Host "⚠️  WARNING: App may be running!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Running processes detected:" -ForegroundColor Yellow
    $runningProcesses | Format-Table ProcessName, Id, MainWindowTitle -AutoSize
    Write-Host ""
    
    if (-not $Force) {
        $response = Read-Host "Stop app first? (Y/N)"
        if ($response -eq "Y" -or $response -eq "y") {
            Write-Host "Please stop the app manually (Ctrl+C in terminal), then run this script again." -ForegroundColor Yellow
            exit 0
        }
    }
}

# Get file info
$fileInfo = Get-Item $dbPath
$fileSize = [math]::Round($fileInfo.Length / 1KB, 2)

Write-Host "Database Info:" -ForegroundColor Cyan
Write-Host "  Size: $fileSize KB"
Write-Host "  Created: $($fileInfo.CreationTime)"
Write-Host "  Modified: $($fileInfo.LastWriteTime)"
Write-Host ""

# Confirm deletion
if (-not $Force) {
    Write-Host "⚠️  This will DELETE the database!" -ForegroundColor Yellow
    Write-Host "   All data will be lost!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "Type 'YES' to confirm"
    
    if ($confirm -ne "YES") {
        Write-Host ""
        Write-Host "❌ Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Deleting database..." -ForegroundColor Cyan

try {
    Remove-Item $dbPath -Force
    Write-Host "✅ Database deleted successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run: flutter run -d windows" -ForegroundColor White
    Write-Host "2. Database will be recreated with new schema" -ForegroundColor White
    Write-Host "3. Tables receivings & receiving_items will be created" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Error deleting database: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible solutions:" -ForegroundColor Yellow
    Write-Host "1. Close all apps/terminals using the database" -ForegroundColor White
    Write-Host "2. Restart computer" -ForegroundColor White
    Write-Host "3. Delete manually via File Explorer" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Ask to run app
$runApp = Read-Host "Run app now? (Y/N)"
if ($runApp -eq "Y" -or $runApp -eq "y") {
    Write-Host ""
    Write-Host "Starting app..." -ForegroundColor Cyan
    flutter run -d windows
}
