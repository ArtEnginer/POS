# Test Script - Multi-User Data Sync Verification

Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     TESTING MULTI-USER DATA SYNC SOLUTION            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Test 1: Check PostgreSQL Product Count
Write-Host "`n[Test 1] Checking PostgreSQL Database..." -ForegroundColor Yellow
Write-Host "Expected: 6 products" -ForegroundColor Gray

# Try to find psql
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue

if ($psqlPath) {
    $pgCount = psql -U postgres -d pos_db -t -c "SELECT COUNT(*) FROM products WHERE deleted_at IS NULL;"
    Write-Host "PostgreSQL Products: $pgCount" -ForegroundColor Green
} else {
    Write-Host "⚠ psql not found. Skipping PostgreSQL check." -ForegroundColor Yellow
    Write-Host "Please manually verify PostgreSQL has 6 products." -ForegroundColor Gray
}

# Test 2: Find and check SQLite Database
Write-Host "`n[Test 2] Checking SQLite Local Cache..." -ForegroundColor Yellow

# Common locations for Flutter app data on Windows
$possiblePaths = @(
    "$env:APPDATA\com.example.pos\pos_local.db",
    "$env:LOCALAPPDATA\com.example.pos\pos_local.db",
    "$env:USERPROFILE\AppData\Roaming\com.example.pos\pos_local.db",
    "$env:USERPROFILE\AppData\Local\com.example.pos\pos_local.db"
)

$dbPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $dbPath = $path
        break
    }
}

if (-not $dbPath) {
    Write-Host "⚠ SQLite database not found at standard locations." -ForegroundColor Yellow
    Write-Host "Searching for pos_local.db..." -ForegroundColor Gray
    
    $found = Get-ChildItem -Path $env:USERPROFILE -Filter "pos_local.db" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($found) {
        $dbPath = $found.FullName
    }
}

if ($dbPath) {
    Write-Host "✓ Found SQLite database at: $dbPath" -ForegroundColor Green
    
    # Check if sqlite3 is available
    $sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
    
    if ($sqlite3) {
        $sqliteCount = sqlite3 $dbPath "SELECT COUNT(*) FROM products WHERE deleted_at IS NULL;"
        Write-Host "SQLite Products: $sqliteCount" -ForegroundColor Green
        
        Write-Host "`n[Test 3] Comparing Counts..." -ForegroundColor Yellow
        if ($pgCount -and $sqliteCount) {
            if ($pgCount.Trim() -eq $sqliteCount.Trim()) {
                Write-Host "✅ SUCCESS: Counts match! ($sqliteCount products)" -ForegroundColor Green
                Write-Host "Data is synchronized between PostgreSQL and SQLite." -ForegroundColor Green
            } else {
                Write-Host "❌ FAIL: Counts don't match!" -ForegroundColor Red
                Write-Host "PostgreSQL: $($pgCount.Trim()) | SQLite: $($sqliteCount.Trim())" -ForegroundColor Red
                Write-Host "`nThis means the sync is not working yet." -ForegroundColor Yellow
                Write-Host "Run the app and navigate to Products screen to trigger sync." -ForegroundColor Yellow
            }
        }
        
        # Show product details
        Write-Host "`n[Test 4] SQLite Product Details..." -ForegroundColor Yellow
        sqlite3 -header -column $dbPath "SELECT id, name, sku, selling_price FROM products WHERE deleted_at IS NULL LIMIT 10;"
        
    } else {
        Write-Host "⚠ sqlite3 CLI not found." -ForegroundColor Yellow
        Write-Host "Install SQLite tools to check database: https://www.sqlite.org/download.html" -ForegroundColor Gray
        Write-Host "`nAlternatively, you can check the database at:" -ForegroundColor Gray
        Write-Host $dbPath -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ SQLite database not found." -ForegroundColor Red
    Write-Host "The app may not have been run yet, or database is in a different location." -ForegroundColor Yellow
    Write-Host "`nPlease run the app first: flutter run -d windows" -ForegroundColor Gray
}

# Test 5: Backend Server Check
Write-Host "`n[Test 5] Checking Backend Server..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/v2/health" -Method GET -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✓ Backend server is running on port 3000" -ForegroundColor Green
} catch {
    Write-Host "⚠ Backend server is not responding." -ForegroundColor Yellow
    Write-Host "Please start backend: cd backend_v2 && npm start" -ForegroundColor Gray
}

# Summary
Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TEST SUMMARY                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`nTo test multi-user sync:" -ForegroundColor White
Write-Host "1. Ensure backend is running: cd backend_v2 && npm start" -ForegroundColor Gray
Write-Host "2. Run the Flutter app: flutter run -d windows" -ForegroundColor Gray
Write-Host "3. Navigate to Products screen (triggers sync)" -ForegroundColor Gray
Write-Host "4. Run this script again to verify counts match" -ForegroundColor Gray
Write-Host "5. Test real-time sync: Open app on 2 machines, create product on one, see it appear on the other" -ForegroundColor Gray

Write-Host "`nExpected Result:" -ForegroundColor White
Write-Host "PostgreSQL count = SQLite count = 6 products" -ForegroundColor Green

Write-Host "`n"
