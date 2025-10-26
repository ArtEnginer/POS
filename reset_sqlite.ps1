# Reset SQLite Database Script
# This will delete the local cache to force a fresh sync

Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        RESET SQLITE DATABASE - FORCE FRESH SYNC       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Common locations for Flutter app data on Windows
$possiblePaths = @(
    "$env:APPDATA\com.example.pos\pos_local.db",
    "$env:LOCALAPPDATA\com.example.pos\pos_local.db",
    "$env:USERPROFILE\AppData\Roaming\com.example.pos\pos_local.db",
    "$env:USERPROFILE\AppData\Local\com.example.pos\pos_local.db",
    "D:\PROYEK\POS\.dart_tool\sqflite_common_ffi\databases\pos_local.db"
)

$dbFound = $false

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        Write-Host "`nFound database at: $path" -ForegroundColor Yellow
        try {
            Remove-Item $path -Force
            Write-Host "✅ Successfully deleted database!" -ForegroundColor Green
            $dbFound = $true
        } catch {
            Write-Host "❌ Failed to delete: $_" -ForegroundColor Red
        }
    }
}

if (-not $dbFound) {
    Write-Host "`n⚠ No database file found at standard locations." -ForegroundColor Yellow
    Write-Host "Searching entire user profile..." -ForegroundColor Gray
    
    $found = Get-ChildItem -Path $env:USERPROFILE -Filter "pos_local.db" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $found) {
        Write-Host "`nFound: $($file.FullName)" -ForegroundColor Yellow
        try {
            Remove-Item $file.FullName -Force
            Write-Host "✅ Deleted!" -ForegroundColor Green
            $dbFound = $true
        } catch {
            Write-Host "❌ Failed to delete: $_" -ForegroundColor Red
        }
    }
}

if ($dbFound) {
    Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║               DATABASE RESET COMPLETE!                ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor White
    Write-Host "1. Run the app: flutter run -d windows" -ForegroundColor Gray
    Write-Host "2. Navigate to Products screen" -ForegroundColor Gray
    Write-Host "3. Database will sync all 5 products from PostgreSQL" -ForegroundColor Gray
} else {
    Write-Host "`n⚠ No database files found. App may not have been run yet." -ForegroundColor Yellow
}

Write-Host "`n"
