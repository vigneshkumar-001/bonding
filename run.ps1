$ErrorActionPreference = "Stop"

$definesFile = Join-Path $PSScriptRoot "dart_defines.json"
if (-not (Test-Path $definesFile)) {
  Write-Error "Missing dart_defines.json. Copy dart_defines.example.json to dart_defines.json and fill values."
}

flutter run --dart-define-from-file="$definesFile"

