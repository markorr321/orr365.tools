<#
.SYNOPSIS
    Points orr365.tools at Cloudflare's nameservers via the GoDaddy API.

.DESCRIPTION
    This is the one step that must happen at the registrar. Everything else
    (zone, custom domains, redirect rule) is handled by setup-cloudflare.ps1.

    Reads credentials from environment variables so nothing sensitive is typed
    into a chat window or left in shell history:

        $env:GODADDY_API_KEY
        $env:GODADDY_API_SECRET

    Get them from https://developer.godaddy.com/keys - choose a PRODUCTION key,
    not OTE (test). See .NOTES about GoDaddy's access restrictions.

    Dry-run by default. Add -Apply to actually change the nameservers.

.EXAMPLE
    $env:GODADDY_API_KEY    = Read-Host "Key"    -AsSecureString | ConvertFrom-SecureString -AsPlainText
    $env:GODADDY_API_SECRET = Read-Host "Secret" -AsSecureString | ConvertFrom-SecureString -AsPlainText

    .\scripts\set-godaddy-nameservers.ps1 -Nameservers 'xxx.ns.cloudflare.com','yyy.ns.cloudflare.com'
    .\scripts\set-godaddy-nameservers.ps1 -Nameservers 'xxx.ns.cloudflare.com','yyy.ns.cloudflare.com' -Apply

.NOTES
    GoDaddy gates production API access. Accounts below their threshold (commonly
    10+ domains, or Discount Domain Club membership) get HTTP 403 ACCESS_DENIED
    on write endpoints. If that happens this script cannot help - change the
    nameservers by hand:

        GoDaddy -> My Products -> orr365.tools -> DNS -> Nameservers
        -> Change -> "I'll use my own nameservers"

    That takes about four clicks and is the same outcome.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string[]] $Nameservers,

    [switch]   $Apply,
    [string]   $Domain = 'orr365.tools'
)

$ErrorActionPreference = 'Stop'
$API = 'https://api.godaddy.com/v1'

function Write-Step  { param($m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Write-Info  { param($m) Write-Host "  [info] $m" -ForegroundColor Gray }
function Write-Plan  { param($m) Write-Host "  [plan] $m" -ForegroundColor Yellow }
function Write-Fail  { param($m) Write-Host "  [fail] $m" -ForegroundColor Red }

# ------------------------------------------------------------ credentials ---

Write-Step 'Authenticating'

# GoDaddy has two auth schemes. Newer personal access tokens (gd_pat_...) use
# a bearer token; older credentials are a key + secret pair sent as "sso-key".
# Verified against this account: the PAT + Bearer combination is the one that
# works - sso-key with a PAT returns 401.
$token  = $env:GODADDY_TOKEN
$key    = $env:GODADDY_API_KEY
$secret = $env:GODADDY_API_SECRET

if ($token) {
    $auth = "Bearer $token"
    Write-Info 'Using personal access token (Bearer)'
}
elseif ($key -and $secret) {
    $auth = "sso-key $($key):$($secret)"
    Write-Info 'Using legacy key + secret (sso-key)'
}
else {
    Write-Host @'
  No GoDaddy credentials found.

  Create a PRODUCTION token at https://developer.godaddy.com/keys then:

      $env:GODADDY_TOKEN = Read-Host "Token" -AsSecureString | ConvertFrom-SecureString -AsPlainText

  (Or set GODADDY_API_KEY + GODADDY_API_SECRET for older key/secret pairs.)
'@ -ForegroundColor Yellow
    exit 1
}

$headers = @{
    'Authorization' = $auth
    'Content-Type'  = 'application/json'
}

function Invoke-GD {
    param([string]$Path, [string]$Method = 'GET', [object]$Body)

    $req = @{ Uri = "$API$Path"; Method = $Method; Headers = $headers }
    if ($Body) { $req['Body'] = ($Body | ConvertTo-Json -Depth 10) }

    try { return Invoke-RestMethod @req }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        $detail = $null
        try {
            $s = $_.Exception.Response.GetResponseStream()
            $detail = (New-Object IO.StreamReader($s)).ReadToEnd()
        } catch { }

        if ($code -eq 403) {
            Write-Fail 'HTTP 403 - GoDaddy denied API access.'
            Write-Info 'Production API writes require a qualifying account (commonly 10+'
            Write-Info 'domains or Discount Domain Club). Change the nameservers manually:'
            Write-Info '  GoDaddy -> My Products -> ' + $Domain + ' -> DNS -> Nameservers -> Change'
            exit 2
        }
        throw "GoDaddy API $Method $Path failed (HTTP $code): $detail"
    }
}

# ------------------------------------------------------------------ check ---

Write-Step "Current state of $Domain"

$info = Invoke-GD -Path "/domains/$Domain"
Write-Ok "Domain found (status: $($info.status))"
Write-Info "Current nameservers: $($info.nameServers -join ', ')"

if ($info.status -ne 'ACTIVE') {
    Write-Fail "Domain status is '$($info.status)' - resolve that at GoDaddy first."
    exit 1
}

$current = @($info.nameServers | Sort-Object)
$target  = @($Nameservers      | Sort-Object)

if (-not (Compare-Object $current $target)) {
    Write-Ok 'Nameservers already match the target. Nothing to do.'
    exit 0
}

# ------------------------------------------------------------------ apply ---

Write-Step 'Nameserver change'

Write-Info "From: $($current -join ', ')"
Write-Info "To:   $($target  -join ', ')"

if (-not $Apply) {
    Write-Plan 'DRY RUN - re-run with -Apply to commit this change.'
    exit 0
}

Invoke-GD -Path "/domains/$Domain" -Method PATCH -Body @{ nameServers = $Nameservers } | Out-Null
Write-Ok 'Nameserver change submitted'

Start-Sleep -Seconds 5
$after = Invoke-GD -Path "/domains/$Domain"
Write-Info "GoDaddy now reports: $($after.nameServers -join ', ')"

Write-Host @"

  Propagation typically takes 15-60 minutes.
  Cloudflare will email you when the zone goes active, then run:

      .\scripts\setup-cloudflare.ps1 -Apply -Wait

"@ -ForegroundColor Green
