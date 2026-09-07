#!/usr/bin/env pwsh
# Dev helper for the MSS Flutter app (Windows / PowerShell).
#
# Runs Flutter with the required build-time configuration so you never hit
#   "Missing build-time configuration: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY".
# Connection values come from dart_defines.json (git-ignored); this script
# always passes --dart-define-from-file so you don't have to remember it.
#
# Usage:
#   ./run.ps1                 # = ./run.ps1 run  (debug on the default device)
#   ./run.ps1 run-release
#   ./run.ps1 apk             # debug APK
#   ./run.ps1 apk-release     # release APK
#   ./run.ps1 appbundle       # release .aab for Play Store
#   ./run.ps1 web
#   ./run.ps1 analyze
#   ./run.ps1 test
param([string]$cmd = "run")

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

$defines = "dart_defines.json"
$example = "dart_defines.example.json"

if (-not (Test-Path $defines)) {
    if (Test-Path $example) {
        Copy-Item $example $defines
        Write-Host "Created $defines from $example." -ForegroundColor Yellow
        Write-Host "Fill in the real SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY, then run again." -ForegroundColor Yellow
    }
    else {
        Write-Host "Missing $defines (and no $example to copy from)." -ForegroundColor Red
    }
    exit 1
}

$flag = "--dart-define-from-file=$defines"

switch ($cmd) {
    "run" { flutter run $flag }
    "run-release" { flutter run --release $flag }
    "apk" { flutter build apk --debug $flag }
    "apk-release" { flutter build apk --release $flag }
    "appbundle" { flutter build appbundle --release $flag }
    "web" { flutter build web --release $flag }
    "analyze" { flutter analyze }
    "test" { flutter test }
    default {
        Write-Host "Unknown command: $cmd"
        Write-Host "Usage: ./run.ps1 [run|run-release|apk|apk-release|appbundle|web|analyze|test]"
        exit 1
    }
}
