# PowerShell Script untuk Migrate Receiving Details
# Script ini akan menambahkan kolom baru ke tabel receivings

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Receiving Details Migration" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Cek apakah flutter sudah terinstall
try {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
    Write-Host "✓ Flutter ditemukan: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter tidak ditemukan. Install Flutter terlebih dahulu." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Migration akan menambahkan kolom baru ke tabel receivings:" -ForegroundColor Yellow
Write-Host "  - invoice_number (TEXT)" -ForegroundColor Yellow
Write-Host "  - delivery_order_number (TEXT)" -ForegroundColor Yellow
Write-Host "  - vehicle_number (TEXT)" -ForegroundColor Yellow
Write-Host "  - driver_name (TEXT)" -ForegroundColor Yellow
Write-Host ""

# Konfirmasi
$response = Read-Host "Lanjutkan migration? (y/n)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "Migration dibatalkan." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Langkah 1: Membersihkan build..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Flutter clean gagal!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Clean berhasil" -ForegroundColor Green

Write-Host ""
Write-Host "Langkah 2: Mendapatkan dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Flutter pub get gagal!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies berhasil diunduh" -ForegroundColor Green

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Migration Info" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database version telah diupdate ke: 7" -ForegroundColor Green
Write-Host ""
Write-Host "Perubahan yang dilakukan:" -ForegroundColor Yellow
Write-Host "1. ✓ Entity Receiving sudah diupdate" -ForegroundColor Green
Write-Host "2. ✓ Model ReceivingModel sudah diupdate" -ForegroundColor Green
Write-Host "3. ✓ Form ReceivingFormPage sudah ditambah input fields" -ForegroundColor Green
Write-Host "4. ✓ Database schema sudah diupdate" -ForegroundColor Green
Write-Host "5. ✓ Migration script sudah ditambahkan" -ForegroundColor Green
Write-Host ""
Write-Host "Saat aplikasi dijalankan, database akan otomatis dimigrate!" -ForegroundColor Cyan
Write-Host ""

# Tanya apakah mau run aplikasi
$runApp = Read-Host "Jalankan aplikasi sekarang? (y/n)"
if ($runApp -eq "y" -or $runApp -eq "Y") {
    Write-Host ""
    Write-Host "Menjalankan aplikasi..." -ForegroundColor Cyan
    flutter run -d windows
} else {
    Write-Host ""
    Write-Host "✓ Migration selesai!" -ForegroundColor Green
    Write-Host "Jalankan 'flutter run -d windows' untuk test perubahan." -ForegroundColor Yellow
}
