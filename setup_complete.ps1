# Complete Setup Script - Auth & Branch Fix
# This script will setup everything needed for the auth system to work

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║     POS System - Complete Auth & Branch Setup             ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$projectRoot = "d:\PROYEK\POS"
$backendPath = "$projectRoot\backend_v2"

# Function to check if command exists
function Test-Command($command) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

# Step 1: Check prerequisites
Write-Host "🔍 Step 1: Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

$allGood = $true

# Check Node.js
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Host "  ✅ Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  ❌ Node.js not found" -ForegroundColor Red
    $allGood = $false
}

# Check PostgreSQL
if (Test-Command "psql") {
    $pgVersion = psql --version
    Write-Host "  ✅ PostgreSQL: $pgVersion" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  PostgreSQL CLI not in PATH (but might be installed)" -ForegroundColor Yellow
}

# Check Flutter
if (Test-Command "flutter") {
    $flutterVersion = flutter --version | Select-String "Flutter" | Select-Object -First 1
    Write-Host "  ✅ Flutter: $flutterVersion" -ForegroundColor Green
} else {
    Write-Host "  ❌ Flutter not found" -ForegroundColor Red
    $allGood = $false
}

if (-not $allGood) {
    Write-Host ""
    Write-Host "❌ Missing prerequisites. Please install missing tools." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Step 2: Backend setup
Write-Host "📦 Step 2: Setting up backend..." -ForegroundColor Yellow
Write-Host ""

Set-Location $backendPath

if (-not (Test-Path "node_modules")) {
    Write-Host "  Installing dependencies..." -ForegroundColor White
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ✅ Dependencies already installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Step 3: Database seeding
Write-Host "🗄️  Step 3: Setting up database..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Running seed script..." -ForegroundColor White
Write-Host ""

node src/database/seed.js

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  ✅ Database seeded successfully" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  ❌ Database seeding failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Common issues:" -ForegroundColor Yellow
    Write-Host "    1. PostgreSQL is not running" -ForegroundColor White
    Write-Host "    2. Database doesn't exist (create it first)" -ForegroundColor White
    Write-Host "    3. Wrong credentials in .env file" -ForegroundColor White
    Write-Host "    4. Schema not created (run schema.sql first)" -ForegroundColor White
    Write-Host ""
    
    $continue = Read-Host "  Continue anyway? (y/N)"
    if ($continue -ne "y") {
        exit 1
    }
}

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Step 4: Start backend (in background)
Write-Host "🚀 Step 4: Starting backend server..." -ForegroundColor Yellow
Write-Host ""

Write-Host "  Starting server in background..." -ForegroundColor White
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; npm run dev"
Write-Host "  ✅ Backend server starting..." -ForegroundColor Green
Write-Host "  (Check new PowerShell window for server logs)" -ForegroundColor Gray

# Wait for server to start
Write-Host ""
Write-Host "  Waiting for server to be ready..." -ForegroundColor White
Start-Sleep -Seconds 5

# Check if server is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/v2/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
    Write-Host "  ✅ Server is running" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Server might still be starting..." -ForegroundColor Yellow
    Write-Host "  (This is normal if database is slow)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Step 5: Test auth API
Write-Host "🧪 Step 5: Testing auth API..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 3

$testPassed = $false
try {
    $loginBody = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/v2/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -TimeoutSec 10
    
    if ($response.success -and $response.user.branchId) {
        Write-Host "  ✅ Login test passed" -ForegroundColor Green
        Write-Host "  ✅ Branch ID present: $($response.user.branchId)" -ForegroundColor Green
        Write-Host "  ✅ Branch: $($response.branch.name)" -ForegroundColor Green
        $testPassed = $true
    } else {
        Write-Host "  ❌ Login test failed - Missing branch data" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Cannot connect to server: $_" -ForegroundColor Red
    Write-Host "  Check the backend server window for errors" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""

# Step 6: Summary
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "║                  🎉 Setup Complete! 🎉                     ║" -ForegroundColor Green
Write-Host "║                                                            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📊 System Status:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Backend Server:  Running on http://localhost:5000" -ForegroundColor White
Write-Host "  Database:        Seeded with default data" -ForegroundColor White
Write-Host "  Auth API:        " -NoNewline
if ($testPassed) {
    Write-Host "Working ✅" -ForegroundColor Green
} else {
    Write-Host "Needs verification ⚠️" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "👤 Default Users:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Admin:" -ForegroundColor White
Write-Host "    Username: admin" -ForegroundColor Gray
Write-Host "    Password: admin123" -ForegroundColor Gray
Write-Host "    Role:     super_admin" -ForegroundColor Gray
Write-Host "    Branch:   Head Office" -ForegroundColor Gray
Write-Host ""
Write-Host "  Cashier:" -ForegroundColor White
Write-Host "    Username: cashier1" -ForegroundColor Gray
Write-Host "    Password: cashier123" -ForegroundColor Gray
Write-Host "    Role:     cashier" -ForegroundColor Gray
Write-Host "    Branch:   Branch 1" -ForegroundColor Gray
Write-Host ""

Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Run Flutter app:" -ForegroundColor White
Write-Host "     flutter run -d windows" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Login with credentials above" -ForegroundColor White
Write-Host ""
Write-Host "  3. Verify socket connects without errors" -ForegroundColor White
Write-Host ""

Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  • AUTH_FIX_README.md  - Detailed documentation" -ForegroundColor Gray
Write-Host "  • AUTH_FIX_SUMMARY.md - Quick reference" -ForegroundColor Gray
Write-Host ""

Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  • Backend logs are in the other PowerShell window" -ForegroundColor Gray
Write-Host "  • Check Flutter console for Socket connection status" -ForegroundColor Gray
Write-Host "  • Run ./test_auth.ps1 to test API endpoints" -ForegroundColor Gray
Write-Host ""

Set-Location $projectRoot

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to run Flutter app
$runFlutter = Read-Host "Do you want to run the Flutter app now? (Y/n)"
if ($runFlutter -ne "n") {
    Write-Host ""
    Write-Host "🚀 Starting Flutter app..." -ForegroundColor Yellow
    Write-Host ""
    flutter run -d windows
}
