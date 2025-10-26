# Script to check SQLite database
# Run this to see what's in the local cache

Write-Host "=== Checking SQLite Database ===" -ForegroundColor Cyan

# Find SQLite database file
$dbPath = "$env:APPDATA\com.example.pos\pos_local.db"

if (-not (Test-Path $dbPath)) {
    # Try alternate path
    $dbPath = "$env:LOCALAPPDATA\com.example.pos\pos_local.db"
}

if (-not (Test-Path $dbPath)) {
    Write-Host "Database file not found at standard locations" -ForegroundColor Yellow
    Write-Host "Searching for pos_local.db..." -ForegroundColor Yellow
    
    # Search in user profile
    $found = Get-ChildItem -Path $env:USERPROFILE -Filter "pos_local.db" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($found) {
        $dbPath = $found.FullName
        Write-Host "Found database at: $dbPath" -ForegroundColor Green
    } else {
        Write-Host "Database not found. App may not have been run yet." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Database found at: $dbPath" -ForegroundColor Green
}

# Check if sqlite3 is available
if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
    Write-Host "`n=== Products in SQLite ===" -ForegroundColor Cyan
    sqlite3 $dbPath "SELECT COUNT(*) as total FROM products WHERE deleted_at IS NULL;"
    
    Write-Host "`n=== Product Details ===" -ForegroundColor Cyan
    sqlite3 $dbPath "SELECT id, name, sku, cost_price, selling_price FROM products WHERE deleted_at IS NULL LIMIT 10;"
} else {
    Write-Host "`nsqlite3 not found. Please install SQLite CLI tools." -ForegroundColor Yellow
    Write-Host "You can check the database manually at: $dbPath" -ForegroundColor Yellow
}
