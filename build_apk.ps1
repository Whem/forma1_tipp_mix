$ErrorActionPreference = "Stop"

$mobileDir = Join-Path $PSScriptRoot "mobile"

Write-Host "=== F1 Tipp Mix - APK Build ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] flutter clean" -ForegroundColor Yellow
flutter clean
Set-Location $mobileDir

Write-Host ""
Write-Host "[2/6] flutter pub get" -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "[3/6] Generating l10n" -ForegroundColor Yellow
flutter gen-l10n

Write-Host ""
Write-Host "[4/6] Generating launcher icons" -ForegroundColor Yellow
dart run flutter_launcher_icons

Write-Host ""
Write-Host "[5/6] Generating native splash" -ForegroundColor Yellow
dart run flutter_native_splash:create

Write-Host ""
Write-Host "[6/6] Building release APK" -ForegroundColor Yellow
flutter build apk --release

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green

$apkPath = Join-Path $mobileDir "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $size = (Get-Item $apkPath).Length / 1MB
    Write-Host "APK: $apkPath" -ForegroundColor Cyan
    Write-Host ("Size: {0:N1} MB" -f $size) -ForegroundColor Cyan
} else {
    Write-Host "WARNING: APK not found at expected path: $apkPath" -ForegroundColor Red
}
