# Reset Local Database Script
# Menghapus database SQLite lokal agar skema baru diterapkan

$dbPath = "$env:APPDATA\com.example\pos\app_flutter\pos.db"

Write-Host "Mencari database di: $dbPath" -ForegroundColor Yellow

if (Test-Path $dbPath) {
    Write-Host "Database ditemukan. Menghapus..." -ForegroundColor Yellow
    Remove-Item $dbPath -Force
    Write-Host "Database berhasil dihapus!" -ForegroundColor Green
} else {
    Write-Host "Database tidak ditemukan (mungkin belum dibuat atau sudah dihapus)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Sekarang jalankan: flutter run -d windows" -ForegroundColor Cyan
Write-Host "Database baru akan dibuat dengan skema yang sudah diperbaiki" -ForegroundColor Cyan
