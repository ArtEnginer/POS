# =====================================================
# Setup MySQL Database for POS System
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   POS MySQL Database Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment variables from .env file
if (Test-Path ".env") {
    Write-Host "✓ Loading environment variables..." -ForegroundColor Green
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)\s*$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Remove quotes if present
            $value = $value -replace '^["'']|["'']$', ''
            Set-Variable -Name $name -Value $value -Scope Script
        }
    }
} else {
    Write-Host "⚠ .env file not found, using default values" -ForegroundColor Yellow
    $DB_HOST = "localhost"
    $DB_PORT = "3306"
    $DB_USER = "root"
    $DB_PASSWORD = ""
    $DB_NAME = "pos_db"
}

Write-Host ""
Write-Host "Database Configuration:" -ForegroundColor Yellow
Write-Host "  Host: $DB_HOST" -ForegroundColor White
Write-Host "  Port: $DB_PORT" -ForegroundColor White
Write-Host "  User: $DB_USER" -ForegroundColor White
Write-Host "  Database: $DB_NAME" -ForegroundColor White
Write-Host ""

# Check if MySQL is accessible
Write-Host "Checking MySQL connection..." -ForegroundColor Yellow

try {
    # Build MySQL command
    $mysqlCmd = "mysql"
    $mysqlArgs = @(
        "-h", $DB_HOST,
        "-P", $DB_PORT,
        "-u", $DB_USER
    )
    
    if ($DB_PASSWORD) {
        $mysqlArgs += "-p$DB_PASSWORD"
    }
    
    # Test connection
    $testQuery = "SELECT VERSION();"
    $result = & $mysqlCmd $mysqlArgs -e $testQuery 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ MySQL connection successful!" -ForegroundColor Green
        Write-Host "  MySQL Version: $($result[1])" -ForegroundColor Gray
    } else {
        throw "Connection failed"
    }
} catch {
    Write-Host "✗ Cannot connect to MySQL server!" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. MySQL server is running" -ForegroundColor White
    Write-Host "  2. Credentials in .env are correct" -ForegroundColor White
    Write-Host "  3. MySQL is installed and accessible from PATH" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Create database if not exists
Write-Host "Creating database '$DB_NAME' if not exists..." -ForegroundColor Yellow
try {
    $createDbQuery = "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    & $mysqlCmd $mysqlArgs -e $createDbQuery
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database '$DB_NAME' ready!" -ForegroundColor Green
    } else {
        throw "Failed to create database"
    }
} catch {
    Write-Host "✗ Error creating database: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Execute SQL script
$sqlFile = "database\create_tables.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "✗ SQL file not found: $sqlFile" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Executing SQL script: $sqlFile" -ForegroundColor Yellow
Write-Host ""

try {
    # Execute the SQL script
    $mysqlArgs += "--database=$DB_NAME"
    $output = & $mysqlCmd $mysqlArgs < $sqlFile 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ SQL script executed successfully!" -ForegroundColor Green
        Write-Host ""
        
        # Show created tables
        Write-Host "Database Tables:" -ForegroundColor Cyan
        $showTablesQuery = "SHOW TABLES;"
        $tables = & $mysqlCmd $mysqlArgs -e $showTablesQuery
        
        $tableCount = 0
        $tables | Select-Object -Skip 1 | ForEach-Object {
            if ($_ -and $_.Trim()) {
                $tableCount++
                Write-Host "  $tableCount. $_" -ForegroundColor White
            }
        }
        
        Write-Host ""
        Write-Host "✓ Total tables created: $tableCount" -ForegroundColor Green
        
    } else {
        throw "Script execution failed"
    }
} catch {
    Write-Host "✗ Error executing SQL script: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Output:" -ForegroundColor Yellow
    Write-Host $output -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Database Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start the backend server: npm start" -ForegroundColor White
Write-Host "  2. Run the Flutter application" -ForegroundColor White
Write-Host "  3. Configure MySQL settings in the app" -ForegroundColor White
Write-Host "  4. Test synchronization" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
