# Quick Fix: Comment out all MySQL imports
$ErrorActionPreference = "Continue"

$files = @(
    "lib\features\customer\data\datasources\customer_local_data_source.dart",
    "lib\features\customer\data\repositories\customer_repository_impl.dart",
    "lib\features\supplier\data\repositories\supplier_repository_impl.dart",
    "lib\features\supplier\data\datasources\supplier_local_data_source.dart",
    "lib\features\sales\presentation\pages\sale_list_page.dart",
    "lib\features\sales\presentation\pages\pos_page.dart",
    "lib\features\sales\data\repositories\sale_repository_impl.dart",
    "lib\features\sales\data\datasources\sale_local_data_source.dart",
    "lib\features\purchase\data\repositories\receiving_repository_impl.dart",
    "lib\features\purchase\data\repositories\purchase_return_repository_impl.dart",
    "lib\features\purchase\data\repositories\purchase_repository_impl.dart",
    "lib\features\purchase\data\datasources\receiving_local_data_source.dart",
    "lib\features\purchase\data\datasources\purchase_return_local_data_source.dart",
    "lib\features\purchase\data\datasources\purchase_local_data_source.dart",
    "lib\features\product\presentation\pages\product_form_page.dart",
    "lib\features\product\data\datasources\product_remote_data_source.dart",
    "lib\core\utils\online_only_guard.dart",
    "lib\features\dashboard\presentation\pages\dashboard_page.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..."
        $content = Get-Content $file -Raw
        $originalContent = $content
        
        $content = $content -replace "import\s+'.*hybrid_sync_manager\.dart';", "// import hybrid_sync_manager; // DELETED"
        $content = $content -replace "import\s+'.*sync_manager\.dart';", "// import sync_manager; // DELETED"
        $content = $content -replace "import\s+'.*connection_status_indicator\.dart';", "// import connection_status_indicator; // DELETED"
        $content = $content -replace "import\s+'mysql_settings_page\.dart';", "// import mysql_settings_page; // DELETED"
        $content = $content -replace "import\s+'.*online_only_guard\.dart';", "// import online_only_guard; // DELETED"
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file -Value $content -NoNewline
            Write-Host "FIXED" -ForegroundColor Green
        }
    }
}
Write-Host "Done"
