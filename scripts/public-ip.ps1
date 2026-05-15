#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche l'adresse IP publique IPv4 (utile pour scdp recv).

.DESCRIPTION
    Équivalent Windows du script scripts/public-ip.sh, sans dépendance externe.
    Utilise uniquement PowerShell et les API publiques IPv4.

.PARAMETER Copy
    Copie l'IP dans le presse-papiers sans demander confirmation.

.PARAMETER Service
    Service à interroger (auto par défaut).

.EXAMPLE
    .\public-ip.ps1

.EXAMPLE
    .\public-ip.ps1 -Copy

.EXAMPLE
    .\public-ip.ps1 -Service ipify

.EXAMPLE
    Get-Help .\public-ip.ps1
#>
[CmdletBinding()]
param(
    [switch]$Copy,
    [ValidateSet('auto', 'ifconfig.me', 'ipify', 'icanhazip', 'ident.me')]
    [string]$Service = 'auto'
)

$ErrorActionPreference = 'Stop'

$ServiceUrls = @{
    'ifconfig.me' = 'https://ifconfig.me/ip'
    'ipify'       = 'https://api.ipify.org'
    'icanhazip'   = 'https://ipv4.icanhazip.com'
    'ident.me'    = 'https://v4.ident.me'
}

$ServiceOrder = @('ifconfig.me', 'ipify', 'icanhazip', 'ident.me')

function Write-Banner {
    $line = '═' * 22
    Write-Host ''
    Write-Host "╔$line╗" -ForegroundColor Magenta
    Write-Host '║  scdp — IP publique  ║' -ForegroundColor Magenta
    Write-Host "╚$line╝" -ForegroundColor Magenta
    Write-Host ''
}

function Get-PublicIpFromUrl {
    param([Parameter(Mandatory)][string]$Url)

    $response = Invoke-RestMethod -Uri $Url -TimeoutSec 10 -ErrorAction Stop
    if ($response -is [string]) {
        return $response.Trim()
    }
    return "$response".Trim()
}

function Get-PublicIp {
    param(
        [string]$ServiceName,
        [string]$StatusLabel
    )

    if ($StatusLabel) {
        Write-Progress -Activity $StatusLabel -Status 'En cours...'
    }

    try {
        if ($ServiceName -eq 'auto') {
            foreach ($name in $ServiceOrder) {
                $url = $ServiceUrls[$name]
                try {
                    $ip = Get-PublicIpFromUrl -Url $url
                    if ($ip) { return $ip }
                } catch {
                    continue
                }
            }
            throw 'Aucun service disponible.'
        }

        if (-not $ServiceUrls.ContainsKey($ServiceName)) {
            throw "Service inconnu: $ServiceName"
        }

        return Get-PublicIpFromUrl -Url $ServiceUrls[$ServiceName]
    } finally {
        Write-Progress -Activity $StatusLabel -Completed -ErrorAction SilentlyContinue
    }
}

function Copy-PublicIp {
    param([Parameter(Mandatory)][string]$Ip)

    Set-Clipboard -Value $Ip
    Write-Host 'Copié dans le presse-papiers.' -ForegroundColor Green
}

function Confirm-Copy {
    param([Parameter(Mandatory)][string]$Ip)

    if ($Copy) {
        Copy-PublicIp -Ip $Ip
        return
    }

    if ([Environment]::UserInteractive) {
        $answer = Read-Host 'Copier l''IP dans le presse-papiers ? (O/n)'
        if ($answer -eq '' -or $answer -match '^[oOyY]') {
            Copy-PublicIp -Ip $Ip
        }
    }
}

try {
    Write-Banner

    $label = if ($Service -eq 'auto') {
        'Récupération de l''IP publique...'
    } else {
        "Interrogation de $Service..."
    }

    $ip = Get-PublicIp -ServiceName $Service -StatusLabel $label

    if (-not $ip) {
        throw 'Réponse vide.'
    }

    Write-Host 'IP publique' -ForegroundColor Cyan
    Write-Host ''
    Write-Host "  $ip" -ForegroundColor White -BackgroundColor DarkGray
    Write-Host ''

    Write-Host 'Utilisation avec scdp :' -ForegroundColor DarkGray
    Write-Host '  scdp recv 9000    # sur cette machine' -ForegroundColor DarkGray
    Write-Host "  scdp send $ip 9000 `"message`"   # depuis l'autre machine" -ForegroundColor DarkGray
    Write-Host ''

    Confirm-Copy -Ip $ip
    exit 0
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}
