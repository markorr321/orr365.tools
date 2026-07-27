/* ==========================================================================
   orr365.tools — TOOL DATA
   --------------------------------------------------------------------------
   This is the ONLY file you need to edit to add, remove or change a tool.
   Copy an entry, change the values, save, refresh. No build step.

   Fields
   ------
   name     (required)  Display name of the tool.
   desc     (required)  One or two sentences. Keep it under ~180 characters.
   url      (required)  Primary link — the tool's GitHub Pages site.
                        The card title and the card background link here.
   cats     (required)  Categories. Must match names in CATEGORIES below.
                        A tool can belong to several.
   repo     (optional)  GitHub repository URL.
   gallery  (optional)  PowerShell Gallery package URL.
   module   (optional)  Module name — renders a copyable `Install-Module` line.
   script   (optional)  Gallery *script* name — renders `Install-Script` instead.
   tags     (optional)  Free-text keywords. Shown as pills, also searchable.
   lang     (optional)  Drives the coloured language dot. See LANG_COLORS.
   badge    (optional)  'new' | 'updated' — small coloured pill on the card.
   docs     (optional)  Extra docs / blog post link.
   ========================================================================== */

const CATEGORIES = [
  'Intune',
  'Entra ID',
  'Microsoft Graph',
  'Autopilot',
  'PowerShell',
  'Windows',
  'GitHub',          // repos with no docs site — card links straight to GitHub
];

/* Language dot colours — GitHub's linguist colours. */
const LANG_COLORS = {
  'PowerShell': '#012456',
  'C#':         '#178600',
  'Python':     '#3572A5',
  'Bicep':      '#519aba',
  'HTML':       '#e34c26',
  'Shell':      '#89e051',
};

const TOOLS = [
  {
    name: 'Access Packages on Demand',
    desc: 'PowerShell TUI for on-demand Entra ID access package assignments. Assign users by email with required justifications, recover stuck requests, and view live assignment state.',
    url: 'https://access-packages.orr365.tech/',
    repo: 'https://github.com/markorr321/Access-Packages-on-Demand',
    gallery: 'https://www.powershellgallery.com/packages/Access-Package-OnDemand',
    module: 'Access-Package-OnDemand',
    cats: ['Entra ID', 'Microsoft Graph', 'PowerShell'],
    tags: ['identity governance', 'entitlement management', 'TUI'],
    lang: 'PowerShell',
    badge: 'updated',
  },
  {
    name: 'Entra PIM',
    desc: 'Activate and deactivate Privileged Identity Management roles from the terminal — Entra ID roles, Azure resource roles and PIM for Groups. Windows, macOS and Linux.',
    url: 'https://entra-pim.orr365.tech/',
    repo: 'https://github.com/markorr321/Entra-PIM',
    gallery: 'https://www.powershellgallery.com/packages/Entra-PIM',
    module: 'Entra-PIM',
    cats: ['Entra ID', 'Microsoft Graph', 'PowerShell'],
    tags: ['PIM', 'privileged access', 'role activation', 'cross-platform'],
    lang: 'PowerShell',
  },
  {
    name: 'Intune LAPS',
    desc: 'Retrieve and rotate Windows LAPS passwords from Entra ID via Microsoft Graph. Device search, clipboard copy and on-demand rotation in an interactive terminal UI.',
    url: 'https://intune-laps.orr365.tech/',
    repo: 'https://github.com/markorr321/Intune-LAPS',
    gallery: 'https://www.powershellgallery.com/packages/Intune-LAPS',
    module: 'Intune-LAPS',
    cats: ['Intune', 'Entra ID', 'Microsoft Graph', 'PowerShell'],
    tags: ['LAPS', 'local admin password', 'MSAL', 'cross-platform'],
    lang: 'PowerShell',
  },
  {
    name: 'Intune MAA',
    desc: 'Review, approve and deny Intune Multi Admin Approval requests from a terminal UI, with full payload detail for apps, policies, scripts and device actions.',
    url: 'https://intune-maa.orr365.tech/',
    repo: 'https://github.com/markorr321/Intune-MAA',
    gallery: 'https://www.powershellgallery.com/packages/Intune-MAA',
    module: 'Intune-MAA',
    cats: ['Intune', 'Microsoft Graph', 'PowerShell'],
    tags: ['multi admin approval', 'change control', 'TUI'],
    lang: 'PowerShell',
  },
  {
    name: 'IROD',
    desc: 'Intune Remediations On-Demand — run remediation scripts against devices when you need them, from a modern WPF interface backed by Microsoft Graph.',
    url: 'https://irod.orr365.tech/',
    repo: 'https://github.com/markorr321/IROD',
    gallery: 'https://www.powershellgallery.com/packages/IROD',
    module: 'IROD',
    cats: ['Intune', 'Microsoft Graph', 'PowerShell', 'Windows'],
    tags: ['remediations', 'WPF', 'GUI'],
    lang: 'PowerShell',
  },
  {
    name: 'Autopilot Cleanup',
    desc: 'Bulk device cleanup across Windows Autopilot, Intune and Entra ID. Serial number validation, real-time deletion monitoring and a WhatIf mode for safe testing.',
    url: 'https://autopilot-cleanup.orr365.tech/',
    repo: 'https://github.com/markorr321/Autopilot-Cleanup',
    gallery: 'https://www.powershellgallery.com/packages/AutopilotCleanup',
    module: 'AutopilotCleanup',
    cats: ['Autopilot', 'Intune', 'Entra ID', 'PowerShell'],
    tags: ['offboarding', 'bulk cleanup', 'WhatIf'],
    lang: 'PowerShell',
  },
  {
    name: 'Get-WindowsAutopilotImportCommunity',
    desc: 'GUI for registering devices with Windows Autopilot during OOBE — v1 hardware hash and v2 Device Preparation IDs, offline CSV export, network and Autopilot diagnostics. One self-contained script.',
    url: 'https://github.com/markorr321/Get-WindowsAutopilotImportCommunity',
    gallery: 'https://www.powershellgallery.com/packages/Get-WindowsAutopilotImportGUICommunity',
    script: 'Get-WindowsAutopilotImportGUICommunity',
    cats: ['Autopilot', 'Intune', 'PowerShell', 'Windows', 'GitHub'],
    tags: ['OOBE', 'hardware hash', 'device preparation', 'GUI'],
    lang: 'PowerShell',
    badge: 'new',
  },

  /* ------------------------------------------------------------------------
     REPO-ONLY ENTRIES
     For repos with no docs site: point `url` straight at GitHub, add the
     'GitHub' category, and omit `repo` (the title already links there).
     Uncomment and edit, or send me the list and I'll fill it in.
     ------------------------------------------------------------------------
  {
    name: 'Graph Permission Manager',
    desc: 'One or two sentences on what it does.',
    url: 'https://github.com/markorr321/Graph-Permission-Manager',
    cats: ['Microsoft Graph', 'PowerShell', 'GitHub'],
    tags: ['permissions', 'app registration'],
    lang: 'PowerShell',
  },
  ------------------------------------------------------------------------ */
];
