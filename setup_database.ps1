# Setup Database with Seed Data
# Run this script to initialize database with default data

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  POS Database Setup & Seeding" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to backend directory
$backendPath = "d:\PROYEK\POS\backend_v2"
Set-Location $backendPath

Write-Host "📦 Checking dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

Write-Host ""
Write-Host "🗄️  Running database seed script..." -ForegroundColor Yellow
Write-Host ""

node src/database/seed.js

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ Database setup completed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now:" -ForegroundColor Cyan
    Write-Host "  1. Start the backend: npm run dev" -ForegroundColor White
    Write-Host "  2. Start the Flutter app: flutter run -d windows" -ForegroundColor White
    Write-Host ""
    Write-Host "Default credentials:" -ForegroundColor Cyan
    Write-Host "  Admin    - username: admin, password: admin123" -ForegroundColor White
    Write-Host "  Cashier  - username: cashier1, password: cashier123" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ❌ Database setup failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. PostgreSQL is running" -ForegroundColor White
    Write-Host "  2. Database credentials in .env file" -ForegroundColor White
    Write-Host "  3. Schema is created (run schema.sql first)" -ForegroundColor White
    Write-Host ""
}

# Return to project root
Set-Location "d:\PROYEK\POS"
