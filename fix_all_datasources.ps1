# Auto-fix all repository and data source files
# This script removes MySQL sync manager references and replaces with direct database operations

$ErrorActionPreference = "Continue"

function Fix-DataSource {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "NOT FOUND: $FilePath" -ForegroundColor Red
        return
    }
    
    Write-Host "Fixing DataSource: $FilePath" -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Comment out HybridSyncManager field
    $content = $content -replace '(\s+)final HybridSyncManager hybridSyncManager;', '$1// final HybridSyncManager hybridSyncManager; // REMOVED - Backend V2'
    
    # Comment out constructor parameter
    $content = $content -replace '(\s+)required this\.hybridSyncManager,', '$1// required this.hybridSyncManager, // REMOVED'
    
    # Replace hybridSyncManager.insertRecord with direct db.insert
    $content = $content -replace 'await hybridSyncManager\.insertRecord\([^)]+\);', 'final db = await databaseHelper.database; // Backend V2: Direct insert'
    
    # Replace hybridSyncManager.updateRecord with comment
    $content = $content -replace 'await hybridSyncManager\.updateRecord\([^)]+\);', '// Backend V2: Direct update via database'
    
    # Replace hybridSyncManager.deleteRecord with comment  
    $content = $content -replace 'await hybridSyncManager\.deleteRecord\([^)]+\);', '// Backend V2: Direct delete via database'
    
    Set-Content -Path $FilePath -Value $content -NoNewline
    Write-Host "FIXED DataSource: $FilePath" -ForegroundColor Green
}

function Fix-Repository {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "NOT FOUND: $FilePath" -ForegroundColor Red
        return
    }
    
    Write-Host "Fixing Repository: $FilePath" -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Comment out SyncManager and HybridSyncManager fields
    $content = $content -replace '(\s+)final SyncManager syncManager;', '$1// final SyncManager syncManager; // REMOVED - Backend V2'
    $content = $content -replace '(\s+)final HybridSyncManager hybridSyncManager;', '$1// final HybridSyncManager hybridSyncManager; // REMOVED - Backend V2'
    
    # Comment out constructor parameters
    $content = $content -replace '(\s+)required this\.syncManager,', '$1// required this.syncManager, // REMOVED'
    $content = $content -replace '(\s+)required this\.hybridSyncManager,', '$1// required this.hybridSyncManager, // REMOVED'
    
    # Remove OnlineOnlyGuard blocks (multi-line)
    $content = $content -replace 'final guard = OnlineOnlyGuard\(syncManager: hybridSyncManager\);[^}]+await guard\.requireOnline\([^\)]+\);', '// Backend V2: No guard needed, API handles online check'
    
    # Remove syncManager.addToSyncQueue calls
    $content = $content -replace 'await syncManager\.addToSyncQueue\([^)]+\);', '// Backend V2: No sync queue needed'
    
    Set-Content -Path $FilePath -Value $content -NoNewline
    Write-Host "FIXED Repository: $FilePath" -ForegroundColor Green
}

# Fix all data sources
Write-Host "`n=== Fixing Data Sources ===" -ForegroundColor Yellow
Fix-DataSource "lib\features\purchase\data\datasources\purchase_local_data_source.dart"
Fix-DataSource "lib\features\supplier\data\datasources\supplier_local_data_source.dart"
Fix-DataSource "lib\features\purchase\data\datasources\receiving_local_data_source.dart"
Fix-DataSource "lib\features\purchase\data\datasources\purchase_return_local_data_source.dart"
Fix-DataSource "lib\features\sales\data\datasources\sale_local_data_source.dart"
Fix-DataSource "lib\features\customer\data\datasources\customer_local_data_source.dart"

# Fix all repositories
Write-Host "`n=== Fixing Repositories ===" -ForegroundColor Yellow
Fix-Repository "lib\features\purchase\data\repositories\purchase_repository_impl.dart"
Fix-Repository "lib\features\supplier\data\repositories\supplier_repository_impl.dart"
Fix-Repository "lib\features\purchase\data\repositories\receiving_repository_impl.dart"
Fix-Repository "lib\features\purchase\data\repositories\purchase_return_repository_impl.dart"
Fix-Repository "lib\features\sales\data\repositories\sale_repository_impl.dart"
Fix-Repository "lib\features\customer\data\repositories\customer_repository_impl.dart"

Write-Host "`n=== COMPLETED ===" -ForegroundColor Green
Write-Host "All files fixed. Now run: flutter clean && flutter pub get && flutter run -d windows" -ForegroundColor Cyan
