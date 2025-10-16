# Database Migration Helper Script
# Run this when you encounter "no such table" error

# OPTION 1: Uninstall and reinstall (RECOMMENDED)
Write-Host "=== DATABASE MIGRATION FIX ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Problem: Database masih versi lama, belum ada tabel 'receivings'" -ForegroundColor Yellow
Write-Host ""
Write-Host "SOLUTION 1: Uninstall & Reinstall App" -ForegroundColor Green
Write-Host "1. Stop running app (Ctrl+C di terminal flutter run)"
Write-Host "2. Uninstall app:"
Write-Host "   - Windows: Settings > Apps > [Your App] > Uninstall"
Write-Host "   - Android: adb uninstall com.yourcompany.pos"
Write-Host "3. Run: flutter run"
Write-Host ""

# Check if app is running
$processes = Get-Process | Where-Object {$_.ProcessName -like "*flutter*" -or $_.ProcessName -like "*pos*"}
if ($processes) {
    Write-Host "WARNING: Flutter/POS processes are still running:" -ForegroundColor Red
    $processes | Format-Table ProcessName, Id
    Write-Host "Please stop them first (Ctrl+C or Task Manager)" -ForegroundColor Red
    Write-Host ""
}

# Offer to clean build
$clean = Read-Host "Do you want to run 'flutter clean'? (y/n)"
if ($clean -eq "y" -or $clean -eq "Y") {
    Write-Host "Running flutter clean..." -ForegroundColor Cyan
    flutter clean
    Write-Host "Clean completed!" -ForegroundColor Green
    Write-Host ""
}

Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Manually uninstall the app from your device/emulator"
Write-Host "2. Run: flutter run"
Write-Host "3. Database will be created with new schema (version 5)"
Write-Host ""

Write-Host "Database v5 includes:" -ForegroundColor Green
Write-Host "  - receivings table (separate from purchases)"
Write-Host "  - receiving_items table"
Write-Host "  - PO data protection (READ ONLY)"
Write-Host "  - Per-item discount & tax support"
Write-Host ""
