# Build dan Setup Script untuk POS App dan Management App

Write-Host "🔨 Building POS Applications..." -ForegroundColor Green

# Install dependencies untuk POS App
Write-Host "`n📦 Installing dependencies for POS App..." -ForegroundColor Cyan
Set-Location "d:\DOKUMEN\EDP\angga\FLUTTER\pos\pos_app"
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install POS App dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "✅ POS App dependencies installed" -ForegroundColor Green

# Install dependencies untuk Management App
Write-Host "`n📦 Installing dependencies for Management App..." -ForegroundColor Cyan
Set-Location "d:\DOKUMEN\EDP\angga\FLUTTER\pos\management_app"
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install Management App dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Management App dependencies installed" -ForegroundColor Green

# Analyze code
Write-Host "`n🔍 Analyzing POS App..." -ForegroundColor Cyan
Set-Location "d:\DOKUMEN\EDP\angga\FLUTTER\pos\pos_app"
flutter analyze --no-fatal-infos

Write-Host "`n🔍 Analyzing Management App..." -ForegroundColor Cyan
Set-Location "d:\DOKUMEN\EDP\angga\FLUTTER\pos\management_app"
flutter analyze --no-fatal-infos

Write-Host "`n✨ Setup completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run POS App: cd pos_app && flutter run -d windows" -ForegroundColor White
Write-Host "2. Run Management App: cd management_app && flutter run -d windows" -ForegroundColor White
