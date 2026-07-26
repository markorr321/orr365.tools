# orr365.tools

Landing site for my Microsoft Intune / Entra ID / Microsoft Graph / PowerShell tooling.

Plain static HTML, CSS and JavaScript — no build step, no dependencies, no npm.

## Adding or changing a tool

Everything lives in one file: [`assets/js/tools.js`](assets/js/tools.js).

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

Open `index.html` directly in a browser, or serve the folder:

```powershell
# PowerShell 7 with Python installed
python -m http.server 8080

# or with Node
npx serve .
```

Then browse to <http://localhost:8080>.

## Deploying to Cloudflare Pages

**First time**

1. Push this folder to a GitHub repo (e.g. `markorr321/orr365.tools`).
2. Cloudflare dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**.
3. Pick the repo. Build settings:
   - Framework preset: **None**
   - Build command: *(leave empty)*
   - Build output directory: `/`
4. **Save and Deploy**.

**Custom domain**

1. Add `orr365.tools` as a site in Cloudflare and point your registrar's
   nameservers at the two Cloudflare nameservers it gives you.
2. In the Pages project → **Custom domains** → **Set up a domain** → `orr365.tools`.
3. Repeat for `www.orr365.tools` if you want it to redirect.

HTTPS certificates are issued automatically. Every push to `main` redeploys.

**No-git alternative:** Workers & Pages → Create → Pages → *Upload assets*, and
drag this folder in. Fine for a one-off, but you lose automatic redeploys.

## Files

| Path                   | Purpose                                              |
| ---------------------- | ---------------------------------------------------- |
| `index.html`           | The whole page — markup and inline SVG icon sprite    |
| `assets/css/styles.css`| GitHub dark (Primer) theme                            |
| `assets/js/tools.js`   | **Tool data — the file you edit**                     |
| `assets/js/app.js`     | Rendering, search and category filtering              |
| `_headers`             | Cloudflare Pages security headers and cache policy    |
| `robots.txt`           | Crawler policy                                        |
| `sitemap.xml`          | Sitemap                                               |
