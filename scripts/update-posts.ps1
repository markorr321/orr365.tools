<#
.SYNOPSIS
    Refreshes the Writing section with the latest Medium posts.

.DESCRIPTION
    Fetches the Medium RSS feed and writes the newest N posts to
    public/assets/js/posts.js as a plain JS array the About page renders.

    Why not fetch the feed in the browser? Two reasons:
      1. The site's CSP is connect-src 'self' - no external requests allowed.
      2. Medium's RSS sends no CORS headers, so a browser fetch fails anyway.

    Baking the data in at build time keeps the site static, fast and
    CSP-clean, and means the page still works if Medium is down.

    Run by .github/workflows/update-posts.yml on a schedule.

.PARAMETER Count
    How many posts to publish. Defaults to 6.

.PARAMETER Feed
    RSS feed URL. Defaults to the Medium feed for @markhunterorr.

.EXAMPLE
    .\scripts\update-posts.ps1
    .\scripts\update-posts.ps1 -Count 8
#>

[CmdletBinding()]
param(
    [int]    $Count = 6,
    [string] $Feed  = 'https://medium.com/feed/@markhunterorr',
    [string] $OutFile
)

$ErrorActionPreference = 'Stop'

if (-not $OutFile) {
    $OutFile = Join-Path $PSScriptRoot '..\public\assets\js\posts.js'
}

Write-Host "Fetching $Feed ..."
$raw = (Invoke-WebRequest $Feed -TimeoutSec 30 -UseBasicParsing).Content
$xml = [xml]$raw

$items = @($xml.rss.channel.item)
if (-not $items -or $items.Count -eq 0) {
    throw "Feed returned no items - refusing to overwrite $OutFile with an empty list."
}

Write-Host "Feed has $($items.Count) item(s); taking newest $Count."

$posts = foreach ($i in ($items | Select-Object -First $Count)) {

    # Titles arrive as CDATA, so .InnerText is the reliable accessor.
    $title = if ($i.title -is [string]) { $i.title } else { $i.title.InnerText }
    $link  = ($i.link -split '\?')[0]          # strip Medium's ?source= tracking
    $date  = [datetime]$i.pubDate

    [pscustomobject]@{
        title = $title.Trim()
        url   = $link.Trim()
        iso   = $date.ToString('yyyy-MM-dd')
        # e.g. "20 Jul 2026" - invariant culture so the runner's locale
        # can't turn this into something unexpected.
        label = $date.ToString('d MMM yyyy', [cultureinfo]::InvariantCulture)
    }
}

# ConvertTo-Json handles escaping of quotes, backslashes and unicode, which
# matters because Medium titles contain em dashes, colons and apostrophes.
$entries = foreach ($p in $posts) {
    @"
  {
    title: $($p.title | ConvertTo-Json),
    url:   $($p.url   | ConvertTo-Json),
    iso:   $($p.iso   | ConvertTo-Json),
    label: $($p.label | ConvertTo-Json),
  },
"@
}

$js = @"
/* ==========================================================================
   orr365.tools - RECENT POSTS
   --------------------------------------------------------------------------
   GENERATED FILE - DO NOT EDIT BY HAND.
   Regenerated from the Medium RSS feed by scripts/update-posts.ps1, run on a
   schedule by .github/workflows/update-posts.yml. Any manual edit here is
   overwritten on the next run.
   ========================================================================== */

const POSTS = [
$($entries -join "`n")
];
"@

$dir = Split-Path $OutFile -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

$js | Set-Content -Path $OutFile -Encoding utf8 -NoNewline
Add-Content -Path $OutFile -Value "`n" -Encoding utf8 -NoNewline

Write-Host "`nWrote $Count post(s) to $OutFile`n"
$posts | ForEach-Object { "  {0}  {1}" -f $_.iso, $_.title }
