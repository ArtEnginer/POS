# Migration Script - Copy files dari lib/ ke pos_app/ dan management_app/

Write-Host "🚀 Starting Migration..." -ForegroundColor Green

$sourceRoot = "d:\DOKUMEN\EDP\angga\FLUTTER\pos\lib"
$posApp = "d:\DOKUMEN\EDP\angga\FLUTTER\pos\pos_app\lib"
$mgmtApp = "d:\DOKUMEN\EDP\angga\FLUTTER\pos\management_app\lib"

# Copy core files ke POS App
Write-Host "`n📦 Copying core files to POS App..." -ForegroundColor Cyan

# Network
Copy-Item "$sourceRoot\core\network\network_info.dart" "$posApp\core\network\network_info.dart" -Force
Write-Host "✅ network_info.dart" -ForegroundColor Green

# Auth
Copy-Item "$sourceRoot\core\auth\auth_service.dart" "$posApp\core\auth\auth_service.dart" -Force
Write-Host "✅ auth_service.dart" -ForegroundColor Green

# Utils
Copy-Item "$sourceRoot\core\utils\*" "$posApp\core\utils\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ utils/" -ForegroundColor Green

# Widgets
Copy-Item "$sourceRoot\core\widgets\*" "$posApp\core\widgets\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ widgets/" -ForegroundColor Green

# Copy features ke POS App (will modify later)
Write-Host "`n📦 Copying features to POS App..." -ForegroundColor Cyan

# Auth feature
Copy-Item "$sourceRoot\features\auth\*" "$posApp\features\auth\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ auth feature" -ForegroundColor Green

# Sales feature
Copy-Item "$sourceRoot\features\sales\*" "$posApp\features\sales\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ sales feature" -ForegroundColor Green

# Product feature (read-only)
Copy-Item "$sourceRoot\features\product\*" "$posApp\features\product\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ product feature" -ForegroundColor Green

# Customer feature (read-only)
Copy-Item "$sourceRoot\features\customer\*" "$posApp\features\customer\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ customer feature" -ForegroundColor Green

# Copy core files ke Management App
Write-Host "`n📦 Copying core files to Management App..." -ForegroundColor Cyan

# Constants (will modify)
Copy-Item "$sourceRoot\core\constants\*" "$mgmtApp\core\constants\" -Recurse -Force
Write-Host "✅ constants/" -ForegroundColor Green

# Theme
Copy-Item "$sourceRoot\core\theme\*" "$mgmtApp\core\theme\" -Recurse -Force
Write-Host "✅ theme/" -ForegroundColor Green

# Network
Copy-Item "$sourceRoot\core\network\*" "$mgmtApp\core\network\" -Recurse -Force
Write-Host "✅ network/" -ForegroundColor Green

# Auth
Copy-Item "$sourceRoot\core\auth\*" "$mgmtApp\core\auth\" -Recurse -Force
Write-Host "✅ auth/" -ForegroundColor Green

# Socket
Copy-Item "$sourceRoot\core\socket\*" "$mgmtApp\core\realtime\" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ socket/realtime" -ForegroundColor Green

# Utils
Copy-Item "$sourceRoot\core\utils\*" "$mgmtApp\core\utils\" -Recurse -Force
Write-Host "✅ utils/" -ForegroundColor Green

# Widgets
Copy-Item "$sourceRoot\core\widgets\*" "$mgmtApp\core\widgets\" -Recurse -Force
Write-Host "✅ widgets/" -ForegroundColor Green

# Copy ALL features ke Management App
Write-Host "`n📦 Copying ALL features to Management App..." -ForegroundColor Cyan

$features = @("auth", "dashboard", "product", "customer", "supplier", "purchase", "branch", "sales")

foreach ($feature in $features) {
    $sourcePath = "$sourceRoot\features\$feature"
    $destPath = "$mgmtApp\features\$feature"
    
    if (Test-Path $sourcePath) {
        Copy-Item "$sourcePath\*" "$destPath\" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ $feature feature" -ForegroundColor Green
    }
}

Write-Host "`n✨ Migration completed!" -ForegroundColor Green
Write-Host "⚠️  Note: Some files need manual modification:" -ForegroundColor Yellow
Write-Host "   - Update API endpoints in repositories" -ForegroundColor Yellow
Write-Host "   - Add offline check in Management App" -ForegroundColor Yellow
Write-Host "   - Modify POS App for read-only features" -ForegroundColor Yellow
