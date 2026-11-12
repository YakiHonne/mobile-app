# Removes only the per-user nostr: handler this project writes.
#
# Use for a clean test reset. It does not touch other handlers you may have
# configured and does not delete application files or user data.
param(
    [switch]$Force
)

$protocol = 'HKCU:\Software\Classes\nostr'
if (-not (Test-Path -LiteralPath $protocol)) {
    Write-Host 'No per-user nostr: handler is registered.'
    exit 0
}

$command = Join-Path $protocol 'shell\open\command'
$current = $null
if (Test-Path -LiteralPath $command) {
    $current = (Get-ItemProperty -LiteralPath $command -ErrorAction SilentlyContinue).'(default)'
}

# Only remove a registration that points at a YakiHonne executable. A different
# application's handler is left untouched.
if ($current -and $current -notmatch '(?i)yakihonne') {
    Write-Warning "The nostr: handler points at another application: $current"
    if (-not $Force) {
        Write-Host 'Refusing to remove it. Re-run with -Force to override.'
        exit 1
    }
}

Remove-Item -LiteralPath $protocol -Recurse -Force
Write-Host 'Removed the per-user nostr: handler.'
