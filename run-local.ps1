param([string]$Device = 'emulator-5554')
Set-Location -LiteralPath $PSScriptRoot
if (-not (Test-Path -LiteralPath 'goong.local.json')) {
    throw 'Missing goong.local.json configuration.'
}
flutter run -d $Device --dart-define-from-file=goong.local.json
