<#
.SYNOPSIS
    Wires orr365.tools to the deployed Cloudflare Worker.

.DESCRIPTION
    Does the whole Cloudflare side of going live:

      1. Creates the orr365.tools zone and prints the nameservers to set at GoDaddy
      2. Waits for the zone to become active once the nameservers propagate
      3. Attaches orr365.tools and www.orr365.tools to the Worker as custom domains
      4. Adds a 301 Redirect Rule sending www -> apex

    Every step is idempotent: existing zones, domains and rules are detected and
    reused rather than duplicated, so it is safe to re-run at any point.

    Runs in dry-run mode by default and changes nothing. Add -Apply to commit.

.PARAMETER Apply
    Actually make changes. Without this, the script only reports what it would do.

.PARAMETER Wait
    After creating the zone, poll until Cloudflare reports it active, then carry
    on to the custom domains and redirect rule in the same run.

.EXAMPLE
    # 1. Create a token (see NOTES), then expose it WITHOUT typing it into chat:
    $env:CLOUDFLARE_API_TOKEN = Read-Host -AsSecureString | ConvertFrom-SecureString -AsPlainText

    # 2. See what would happen:
    .\scripts\setup-cloudflare.ps1

    # 3. Do it:
    .\scripts\setup-cloudflare.ps1 -Apply

.NOTES
    Token: Cloudflare dashboard -> My Profile -> API Tokens -> Create Token ->
    Create Custom Token, with these permissions:

        Account | Workers Scripts   | Edit
        Account | Zone              | Edit      (needed to create the zone)
        Zone    | DNS               | Edit
        Zone    | Dynamic Redirect  | Edit

    Scope it to the orr365 account. Revoke it when this is done.
#>

[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Wait,
    [string]$Domain      = 'orr365.tools',
    [string]$WorkerName  = 'orr365tools',
    [string]$AccountId   = 'dde7bfe36624440dac1350dc4c2666c0',
    [int]   $WaitMinutes = 30
)

$ErrorActionPreference = 'Stop'
$API = 'https://api.cloudflare.com/client/v4'

# ---------------------------------------------------------------- helpers ---

function Write-Step  { param($m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Write-Info  { param($m) Write-Host "  [info] $m" -ForegroundColor Gray }
function Write-Plan  { param($m) Write-Host "  [plan] $m" -ForegroundColor Yellow }
function Write-Warn2 { param($m) Write-Host "  [warn] $m" -ForegroundColor Yellow }

function Invoke-CF {
    <#  Thin wrapper over the Cloudflare API that surfaces their error
        messages properly instead of a bare 400.  #>
    param(
        [Parameter(Mandatory)] [string] $Path,
        [string] $Method = 'GET',
        [object] $Body
    )

    $headers = @{
        'Authorization' = "Bearer $script:Token"
        'Content-Type'  = 'application/json'
    }

    # NB: not $args - that is an automatic variable inside a function.
    $req = @{
        Uri     = "$API$Path"
        Method  = $Method
        Headers = $headers
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        $req['Body'] = ($Body | ConvertTo-Json -Depth 10 -Compress)
    }

    try {
        $r = Invoke-RestMethod @req
    }
    catch {
        $detail = $null
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $detail = (New-Object IO.StreamReader($stream)).ReadToEnd() | ConvertFrom-Json
        } catch { }

        if ($detail -and $detail.errors) {
            $msg = ($detail.errors | ForEach-Object { "$($_.code): $($_.message)" }) -join '; '
            throw "Cloudflare API $Method $Path failed - $msg"
        }
        throw "Cloudflare API $Method $Path failed - $($_.Exception.Message)"
    }

    if (-not $r.success) {
        $msg = ($r.errors | ForEach-Object { "$($_.code): $($_.message)" }) -join '; '
        throw "Cloudflare API $Method $Path returned failure - $msg"
    }
    return $r
}

# ------------------------------------------------------------------ token ---

Write-Step 'Authenticating'

$script:Token = $env:CLOUDFLARE_API_TOKEN
if (-not $script:Token) {
    Write-Host @'
  CLOUDFLARE_API_TOKEN is not set.

  Create a token (see the .NOTES section at the top of this script for the exact
  permissions), then set it in this shell WITHOUT it appearing in your history:

      $env:CLOUDFLARE_API_TOKEN = Read-Host "Paste token" -AsSecureString |
          ConvertFrom-SecureString -AsPlainText

  Then re-run this script.
'@ -ForegroundColor Yellow
    exit 1
}

$verify = Invoke-CF -Path '/user/tokens/verify'
Write-Ok "Token valid (status: $($verify.result.status))"

if (-not $Apply) {
    Write-Warn2 'DRY RUN - no changes will be made. Re-run with -Apply to commit.'
}

# ------------------------------------------------------------------- zone ---

Write-Step "Zone: $Domain"

$zone = (Invoke-CF -Path "/zones?name=$Domain").result | Select-Object -First 1

if ($zone) {
    Write-Ok "Zone already exists (id $($zone.id), status '$($zone.status)')"
}
elseif (-not $Apply) {
    Write-Plan "Would create zone $Domain in account $AccountId"
}
else {
    $zone = (Invoke-CF -Path '/zones' -Method POST -Body @{
        name    = $Domain
        account = @{ id = $AccountId }
        type    = 'full'
    }).result
    Write-Ok "Created zone $Domain (id $($zone.id))"
}

if ($zone -and $zone.status -ne 'active') {
    Write-Host "`n  ------------------------------------------------------------------"
    Write-Host "   ACTION REQUIRED - set these nameservers on $Domain at GoDaddy:" -ForegroundColor Yellow
    $zone.name_servers | ForEach-Object { Write-Host "       $_" -ForegroundColor White }
    Write-Host "   GoDaddy -> My Products -> $Domain -> DNS -> Nameservers ->"
    Write-Host "   Change -> 'I'll use my own nameservers'"
    Write-Host "  ------------------------------------------------------------------`n"
}

# ------------------------------------------------------- wait for activation --

if ($zone -and $zone.status -ne 'active' -and $Wait) {
    Write-Step "Waiting for zone activation (up to $WaitMinutes min)"
    $deadline = (Get-Date).AddMinutes($WaitMinutes)

    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 30
        $zone = (Invoke-CF -Path "/zones/$($zone.id)").result
        if ($zone.status -eq 'active') { Write-Ok 'Zone is active'; break }
        Write-Info "status '$($zone.status)' - still waiting..."
    }

    if ($zone.status -ne 'active') {
        Write-Warn2 "Zone still '$($zone.status)'. Nameserver changes can take a few hours."
        Write-Warn2 'Re-run this script once Cloudflare emails you that the zone is active.'
        exit 0
    }
}

if (-not $zone -or $zone.status -ne 'active') {
    Write-Info 'Zone is not active yet - stopping here.'
    Write-Info 'Re-run with -Apply (optionally -Wait) once the nameservers have propagated.'
    exit 0
}

# -------------------------------------------------------- custom domains ----

Write-Step 'Worker custom domains'

$existing = (Invoke-CF -Path "/accounts/$AccountId/workers/domains").result

# NB: not $host - that is a read-only automatic variable in PowerShell.
foreach ($fqdn in @($Domain, "www.$Domain")) {

    $match = $existing | Where-Object { $_.hostname -eq $fqdn -and $_.service -eq $WorkerName }

    if ($match) {
        Write-Ok "$fqdn already attached to worker '$WorkerName'"
        continue
    }
    if (-not $Apply) {
        Write-Plan "Would attach $fqdn to worker '$WorkerName'"
        continue
    }

    try {
        Invoke-CF -Path "/accounts/$AccountId/workers/domains" -Method PUT -Body @{
            environment = 'production'
            hostname    = $fqdn
            service     = $WorkerName
            zone_id     = $zone.id
        } | Out-Null
        Write-Ok "Attached $fqdn -> $WorkerName"
    }
    catch {
        Write-Warn2 "Could not attach $fqdn - $($_.Exception.Message)"
    }
}

# --------------------------------------------------- www -> apex redirect ---

Write-Step 'Redirect rule: www -> apex (301)'

$phase    = 'http_request_dynamic_redirect'
$ruleDesc = "Redirect www.$Domain to $Domain"

$ruleset = $null
try {
    $ruleset = (Invoke-CF -Path "/zones/$($zone.id)/rulesets/phases/$phase/entrypoint").result
} catch {
    Write-Info 'No dynamic redirect ruleset yet - one will be created.'
}

if ($ruleset -and ($ruleset.rules | Where-Object { $_.description -eq $ruleDesc })) {
    Write-Ok 'Redirect rule already present'
}
elseif (-not $Apply) {
    Write-Plan "Would add 301 redirect: www.$Domain/* -> https://$Domain/*"
}
else {
    $rule = @{
        description = $ruleDesc
        expression  = "(http.host eq `"www.$Domain`")"
        action      = 'redirect'
        action_parameters = @{
            from_value = @{
                status_code = 301
                target_url  = @{
                    expression = "concat(`"https://$Domain`", http.request.uri.path)"
                }
                preserve_query_string = $true
            }
        }
    }

    if ($ruleset) {
        Invoke-CF -Path "/zones/$($zone.id)/rulesets/$($ruleset.id)/rules" -Method POST -Body $rule | Out-Null
    }
    else {
        Invoke-CF -Path "/zones/$($zone.id)/rulesets" -Method POST -Body @{
            name  = 'default'
            kind  = 'zone'
            phase = $phase
            rules = @($rule)
        } | Out-Null
    }
    Write-Ok "Added 301: www.$Domain -> $Domain"
}

# ----------------------------------------------------------------- verify ---

Write-Step 'Verifying'

foreach ($u in @("https://$Domain/", "https://www.$Domain/")) {
    try {
        $r = Invoke-WebRequest $u -Method Head -TimeoutSec 20 -MaximumRedirection 0 -ErrorAction Stop
        Write-Ok "$u -> HTTP $($r.StatusCode)"
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -in 301, 302, 308) {
            Write-Ok "$u -> HTTP $code -> $($_.Exception.Response.Headers.Location)"
        }
        else {
            Write-Info "$u not serving yet ($(if ($code) { "HTTP $code" } else { 'DNS/TLS still propagating' }))"
        }
    }
}

Write-Host "`nDone.`n" -ForegroundColor Green
