# PowerShell script untuk migrasi database sales
# Menambahkan kolom cashier_name ke tabel transactions

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  MIGRASI DATABASE PENJUALAN" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Script ini akan:" -ForegroundColor Yellow
Write-Host "1. Menambahkan kolom cashier_name ke tabel transactions (jika belum ada)" -ForegroundColor White
Write-Host "2. Mengupdate database version menjadi 8" -ForegroundColor White
Write-Host ""

# Confirm
$confirm = Read-Host "Lanjutkan migrasi? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Migrasi dibatalkan." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Memulai migrasi..." -ForegroundColor Green
Write-Host ""

# Path ke database
$dbPath = "$env:LOCALAPPDATA\pos_local.db"

Write-Host "Lokasi database: $dbPath" -ForegroundColor Cyan

# Check if database exists
if (-not (Test-Path $dbPath)) {
    Write-Host "Database tidak ditemukan. Akan dibuat saat aplikasi dijalankan." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Silakan jalankan aplikasi untuk membuat database baru dengan schema terbaru." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

Write-Host ""
Write-Host "Database ditemukan. Migrasi akan dilakukan saat aplikasi berikutnya dijalankan." -ForegroundColor Green
Write-Host ""
Write-Host "Yang dilakukan oleh sistem:" -ForegroundColor Yellow
Write-Host "- Database version akan diupdate dari 7 ke 8" -ForegroundColor White
Write-Host "- Kolom cashier_name akan ditambahkan ke tabel transactions" -ForegroundColor White
Write-Host "- Data yang sudah ada akan diberi nilai default 'Kasir'" -ForegroundColor White
Write-Host ""

Write-Host "SELESAI!" -ForegroundColor Green
Write-Host ""
Write-Host "Langkah selanjutnya:" -ForegroundColor Yellow
Write-Host "1. Jalankan aplikasi: flutter run -d windows" -ForegroundColor White
Write-Host "2. Database akan otomatis di-upgrade" -ForegroundColor White
Write-Host "3. Coba tambah transaksi penjualan baru" -ForegroundColor White
Write-Host ""

pause
