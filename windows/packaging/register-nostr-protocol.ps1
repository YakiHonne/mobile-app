param(
    [Parameter(Mandatory = $true)]
    [string]$ExecutablePath
)

$resolved = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
if (-not [System.IO.Path]::IsPathRooted($resolved) -or
    [System.IO.Path]::GetExtension($resolved) -ne '.exe') {
    throw 'Provide the full path to the installed YakiHonne executable.'
}

$protocol = 'HKCU:\Software\Classes\nostr'
$command = Join-Path $protocol 'shell\open\command'

# Do not silently replace another application's Nostr handler. The user must
# explicitly opt in when a different handler already exists.
if (Test-Path -LiteralPath $command) {
    $existing = (Get-ItemProperty -LiteralPath $command -ErrorAction SilentlyContinue).'(default)'
    if ($existing -and $existing -notmatch '(?i)yakihonne') {
        Write-Warning "A different nostr: handler is already registered: $existing"
        $answer = Read-Host 'Replace it with YakiHonne? [y/N]'
        if ($answer -ne 'y' -and $answer -ne 'Y') {
            Write-Host 'No changes made.'
            exit 0
        }
    }
}

New-Item -Path $protocol -Force | Out-Null
Set-Item -Path $protocol -Value 'URL:Nostr Protocol'
New-ItemProperty -Path $protocol -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
$defaultIcon = Join-Path $protocol 'DefaultIcon'
New-Item -Path $defaultIcon -Force | Out-Null
Set-Item -Path $defaultIcon -Value ('"{0}",0' -f $resolved)
New-Item -Path $command -Force | Out-Null
Set-Item -Path $command -Value ('"{0}" "%1"' -f $resolved)
Write-Host 'Registered YakiHonne for nostr: links. The default handler is still your choice in Windows Settings.'
