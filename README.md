# orr365.tools

Landing site for my Microsoft Intune / Entra ID / Microsoft Graph / PowerShell tooling.

Plain static HTML, CSS and JavaScript — no build step, no dependencies, no npm.

## Adding or changing a tool

Everything lives in one file: [`public/assets/js/tools.js`](public/assets/js/tools.js).

Copy an existing entry, change the values, save, refresh the browser:

```js
{
  name: 'My New Tool',
  desc: 'One or two sentences describing what it does.',
  url:  'https://my-new-tool.orr365.tech/',   // the GitHub Pages site — card links here
  repo: 'https://github.com/markorr321/My-New-Tool',
  gallery: 'https://www.powershellgallery.com/packages/MyNewTool',
  module: 'MyNewTool',                  // renders a copyable `Install-Module` line
  cats: ['Intune', 'PowerShell'],       // must match CATEGORIES at the top of the file
  tags: ['keyword', 'another keyword'], // optional — shown as pills, also searchable
  lang: 'PowerShell',                   // optional — coloured language dot
  badge: 'new',                         // optional — 'new' or 'updated'
  docs: 'https://...',                  // optional — extra "Docs" link
},
```

Category filter chips are generated automatically and hide themselves when no tool
uses that category, so you can add a new category to `CATEGORIES` at any time.

## Running it locally

Open `public/index.html` directly in a browser, or serve the folder:

```powershell
npx wrangler dev      # serves public/ exactly as Cloudflare will
```

## Deploying

Deployed on **Cloudflare Workers static assets**, configured by
[`wrangler.jsonc`](wrangler.jsonc). Every push to `main` redeploys automatically.

**Only `public/` is ever uploaded.** This is deliberate: an earlier build used the
repo root as the asset directory and served `.git/` — including `.git/config` and
every object — as public web files. Keep the asset directory pointed at `public/`
and never move site files back to the root.

### Custom domain

DNS for `orr365.tools` is at GoDaddy, so records are added there rather than in
Cloudflare:

| Type  | Name  | Value                        |
| ----- | ----- | ---------------------------- |
| A     | `@`   | `162.159.152.4`              |
| A     | `@`   | `162.159.153.4`              |
| CNAME | `www` | `orr365tools.workers.dev`    |

Remove GoDaddy's parking records (`3.33.130.190`, `15.197.148.33`) first.

### www → apex redirect

Workers static assets only accepts **relative** URLs in `_redirects`, so a
cross-hostname redirect cannot live in this repo — that is what broke the first
build. Options:

1. Add `www.orr365.tools` as a second custom domain. Both hostnames serve the
   site; the `<link rel="canonical">` tag on each page tells search engines the
   apex is authoritative. Simplest, and good enough.
2. Move DNS to Cloudflare and add a **Redirect Rule** for a true 301.

## Files

| Path                          | Purpose                                           |
| ----------------------------- | ------------------------------------------------- |
| `wrangler.jsonc`              | Cloudflare config — sets `public/` as the assets dir |
| `public/index.html`           | Home page — markup and inline SVG icon sprite      |
| `public/about.html`           | About page                                         |
| `public/404.html`             | Not-found page                                     |
| `public/assets/css/styles.css`| GitHub dark (Primer) theme                         |
| `public/assets/js/tools.js`   | **Tool data — the file you edit**                  |
| `public/assets/js/app.js`     | Rendering, search and category filtering           |
| `public/assets/js/about.js`   | About page tools strip                             |
| `public/_headers`             | Security headers and cache policy                  |
| `public/robots.txt`           | Crawler policy                                     |
| `public/sitemap.xml`          | Sitemap                                            |
