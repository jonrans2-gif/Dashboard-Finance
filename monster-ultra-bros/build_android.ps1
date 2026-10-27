# Bouwt een ondertekende release-APK van Monster Ultra Bros op Windows 11.
# Vereist: Godot 4.7.x (godot.exe op PATH of via $env:GODOT), Android export
# templates, Android SDK + JDK ingesteld in Godot (Editor Settings > Export > Android)
# en een keystore (zie README.md).
#
#   $env:MUB_KEYSTORE="C:\pad\naar\release.keystore"
#   $env:MUB_KEY_ALIAS="monsterultrabros"
#   $env:MUB_KEY_PASS="jouw-wachtwoord"
#   .\build_android.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
foreach ($v in "MUB_KEYSTORE", "MUB_KEY_ALIAS", "MUB_KEY_PASS") {
    if (-not (Get-Item "env:$v" -ErrorAction SilentlyContinue)) { throw "Zet eerst `$env:$v" }
}
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $env:MUB_KEYSTORE
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $env:MUB_KEY_ALIAS
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $env:MUB_KEY_PASS
New-Item -ItemType Directory -Force build | Out-Null
& $godot --headless --path . --import
& $godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
if ($LASTEXITCODE -ne 0) { throw "Tests mislukt ($LASTEXITCODE gefaalde checks)" }
& $godot --headless --path . --export-release Android build/MonsterUltraBros.apk
Write-Host "APK: $PWD\build\MonsterUltraBros.apk"
