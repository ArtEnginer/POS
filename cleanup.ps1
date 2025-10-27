# Cleanup Script - Remove old monolith code after migration

Write-Host "🧹 Starting Cleanup..." -ForegroundColor Yellow
Write-Host "⚠️  This will remove the old monolith code (lib/ folder)" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Are you sure you want to proceed? Type 'YES' to continue"

if ($confirmation -ne 'YES') {
    Write-Host "❌ Cleanup cancelled" -ForegroundColor Yellow
    exit
}

Write-Host "`n📂 Removing old folders..." -ForegroundColor Cyan

$foldersToRemove = @(
    "lib",
    "test"
)

foreach ($folder in $foldersToRemove) {
    $path = "d:\DOKUMEN\EDP\angga\FLUTTER\pos\$folder"
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "✅ Removed: $folder/" -ForegroundColor Green
    } else {
        Write-Host "⏭️  Skipped: $folder/ (not found)" -ForegroundColor Yellow
    }
}

Write-Host "`n📄 Removing old files..." -ForegroundColor Cyan

$filesToRemove = @(
    "pubspec.yaml",
    "pubspec.lock",
    "analysis_options.yaml",
    ".metadata",
    "pos.iml",
    "devtools_options.yaml"
)

foreach ($file in $filesToRemove) {
    $path = "d:\DOKUMEN\EDP\angga\FLUTTER\pos\$file"
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Host "✅ Removed: $file" -ForegroundColor Green
    } else {
        Write-Host "⏭️  Skipped: $file (not found)" -ForegroundColor Yellow
    }
}

Write-Host "`n📦 Removing platform-specific folders (optional)..." -ForegroundColor Cyan

$platformFolders = @(
    "android",
    "ios",
    "linux",
    "macos",
    "web",
    "windows"
)

$removePlatforms = Read-Host "Do you want to remove platform folders (android, ios, etc.)? Type 'YES' to remove"

if ($removePlatforms -eq 'YES') {
    foreach ($folder in $platformFolders) {
        $path = "d:\DOKUMEN\EDP\angga\FLUTTER\pos\$folder"
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force
            Write-Host "✅ Removed: $folder/" -ForegroundColor Green
        }
    }
} else {
    Write-Host "⏭️  Kept platform folders" -ForegroundColor Yellow
}

Write-Host "`n🗑️  Removing temporary/build files..." -ForegroundColor Cyan

$tempFolders = @(
    ".dart_tool",
    "build"
)

foreach ($folder in $tempFolders) {
    $path = "d:\DOKUMEN\EDP\angga\FLUTTER\pos\$folder"
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force
        Write-Host "✅ Removed: $folder/" -ForegroundColor Green
    }
}

Write-Host "`n✨ Cleanup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Remaining structure:" -ForegroundColor Cyan
Write-Host "   pos/" -ForegroundColor White
Write-Host "   ├── pos_app/              # POS Cashier App" -ForegroundColor Green
Write-Host "   ├── management_app/       # Management App" -ForegroundColor Green
Write-Host "   ├── backend_v2/           # Backend Server" -ForegroundColor Green
Write-Host "   ├── assets/               # Shared assets" -ForegroundColor Yellow
Write-Host "   ├── scripts/              # Helper scripts" -ForegroundColor Yellow
Write-Host "   └── *.md                  # Documentation" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎉 Migration and cleanup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Test POS App: cd pos_app && flutter run -d windows" -ForegroundColor White
Write-Host "2. Test Management App: cd management_app && flutter run -d windows" -ForegroundColor White
Write-Host "3. Update backend routes (see IMPLEMENTATION_GUIDE.md)" -ForegroundColor White
