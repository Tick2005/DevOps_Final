$versionFile = "tier2-docker-compose/public/assets/js/version.js"

if (-not (Test-Path $versionFile)) {
  Write-Error "Missing $versionFile"
  exit 1
}

$envName = if ($args.Count -gt 0) { $args[0] } else { "staging" }
$newVersion = "v{0:yyyy.MM.dd}-{0:HHmmss}" -f (Get-Date)

$content = @"
window.APP_UI_VERSION = "$newVersion";
window.APP_RUNTIME_ENV = "$envName";
"@

Set-Content -Path $versionFile -Value $content -NoNewline
Write-Output "Updated UI demo version to $newVersion (env=$envName)"
