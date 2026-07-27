/* ==========================================================================
   orr365.tools — rendering, search and filtering
   You shouldn't need to edit this file to add tools; edit tools.js instead.
   ========================================================================== */

(function () {
  'use strict';

  const grid       = document.getElementById('grid');
  const filtersEl  = document.getElementById('filters');
  const searchEl   = document.getElementById('search');
  const emptyEl    = document.getElementById('empty');
  const countEl    = document.querySelector('[data-stat="count"]');
  const galleryEl  = document.querySelector('[data-stat="gallery"]');
  const yearEl     = document.getElementById('year');

  let activeCat = 'All';
  let query     = '';

  /* ---------------------------------------------------------------- utils */

  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[c]));

  function debounce(fn, wait) {
    let t;
    return function () {
      clearTimeout(t);
      t = setTimeout(() => fn.apply(this, arguments), wait);
    };
  }

  /* Everything a tool can be matched against, lowercased once up front. */
  const haystack = (t) => [
    t.name, t.desc, t.lang,
    (t.cats || []).join(' '),
    (t.tags || []).join(' ')
  ].join(' ').toLowerCase();

  TOOLS.forEach((t) => { t._search = haystack(t); });

  /* --------------------------------------------------------------- render */

  function iconLink(href, icon, label) {
    return `<a href="${esc(href)}" target="_blank" rel="noopener"
              ><svg class="icon" aria-hidden="true"><use href="#${icon}"></use></svg>${esc(label)}</a>`;
  }

  function cardHTML(t) {
    const badge = t.badge
      ? `<span class="card__badge card__badge--${esc(t.badge)}">${esc(t.badge)}</span>`
      : '';

    const tags = (t.tags || []).length
      ? `<ul class="card__tags">${t.tags
          .map((tag) => `<li class="card__tag">${esc(tag)}</li>`)
          .join('')}</ul>`
      : '';

    const lang = t.lang
      ? `<span class="card__lang"
           ><span class="card__dot" style="background:${esc(LANG_COLORS[t.lang] || '#6e7681')}"
           ></span>${esc(t.lang)}</span>`
      : '';

    // Repo-only entries point `url` straight at GitHub and omit `repo`.
    const repoUrl = t.repo || (/^https:\/\/github\.com\//.test(t.url) ? t.url : '');

    const links = [
      repoUrl   ? iconLink(repoUrl, 'i-github', 'Repo')         : '',
      t.gallery ? iconLink(t.gallery, 'i-download', 'Gallery')  : '',
      t.docs    ? iconLink(t.docs, 'i-book', 'Docs')            : '',
    ].join('');

    // `module` → Install-Module, `script` → Install-Script (Gallery scripts).
    const cmd = t.module ? `Install-Module ${t.module}`
              : t.script ? `Install-Script ${t.script}`
              : '';

    const install = cmd
      ? `<div class="card__install">
           <code>${esc(cmd)}</code>
           <button type="button" class="card__copy"
                   data-copy="${esc(cmd)}"
                   aria-label="Copy install command for ${esc(t.name)}">
             <svg class="icon" aria-hidden="true"><use href="#i-copy"></use></svg>
           </button>
         </div>`
      : '';

    return `
      <article class="card">
        <div class="card__head">
          <svg class="icon" aria-hidden="true"><use href="#i-repo"></use></svg>
          <h3 class="card__title">
            <a href="${esc(t.url)}" target="_blank" rel="noopener">${esc(t.name)}</a>
          </h3>
          ${badge}
        </div>
        <p class="card__desc">${esc(t.desc)}</p>
        ${tags}
        ${install}
        <div class="card__foot">
          ${lang}
          <div class="card__links">${links}</div>
        </div>
      </article>`;
  }

  function matches(t) {
    const catOk = activeCat === 'All' || (t.cats || []).includes(activeCat);
    const qOk   = !query || t._search.includes(query);
    return catOk && qOk;
  }

  function render() {
    const visible = TOOLS.filter(matches);
    grid.innerHTML = visible.map(cardHTML).join('');
    emptyEl.hidden = visible.length > 0;
  }

  /* -------------------------------------------------------------- filters */

  function buildFilters() {
    const counts = { All: TOOLS.length };
    CATEGORIES.forEach((c) => {
      counts[c] = TOOLS.filter((t) => (t.cats || []).includes(c)).length;
    });

    // Hide categories that nothing uses yet.
    const shown = ['All'].concat(CATEGORIES.filter((c) => counts[c] > 0));

    filtersEl.innerHTML = shown.map((c) => `
      <button type="button" class="chip"
              data-cat="${esc(c)}"
              aria-pressed="${c === activeCat}">
        ${esc(c)}<span class="chip__count">${counts[c]}</span>
      </button>`).join('');
  }

  filtersEl.addEventListener('click', (e) => {
    const btn = e.target.closest('.chip');
    if (!btn) return;
    activeCat = btn.dataset.cat;
    filtersEl.querySelectorAll('.chip').forEach((c) => {
      c.setAttribute('aria-pressed', String(c.dataset.cat === activeCat));
    });
    render();
  });

  /* ----------------------------------------------------- copy to clipboard */

  grid.addEventListener('click', (e) => {
    const btn = e.target.closest('.card__copy');
    if (!btn) return;
    e.preventDefault();          // don't follow the card's stretched link
    e.stopPropagation();

    navigator.clipboard.writeText(btn.dataset.copy).then(() => {
      btn.classList.add('is-copied');
      setTimeout(() => btn.classList.remove('is-copied'), 1400);
    }).catch(() => {
      // Clipboard API needs a secure context; select the text as a fallback.
      const code = btn.previousElementSibling;
      const range = document.createRange();
      range.selectNodeContents(code);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    });
  });

  /* --------------------------------------------------------------- search */

  searchEl.addEventListener('input', debounce(function () {
    query = this.value.trim().toLowerCase();
    render();
  }, 120));

  // "/" focuses search, Escape clears it — same as GitHub.
  document.addEventListener('keydown', (e) => {
    const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName);
    if (e.key === '/' && !typing) {
      e.preventDefault();
      searchEl.focus();
    } else if (e.key === 'Escape' && document.activeElement === searchEl) {
      searchEl.value = '';
      query = '';
      render();
      searchEl.blur();
    }
  });

  /* ----------------------------------------------------------------- init */

  countEl.textContent   = TOOLS.length;
  galleryEl.textContent = TOOLS.filter((t) => t.gallery).length;
  yearEl.textContent  = new Date().getFullYear();
  buildFilters();
  render();
})();
