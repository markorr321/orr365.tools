/* ==========================================================================
   orr365.tools — about page
   Renders the compact tools strip from the shared TOOLS data in tools.js,
   so the About page never drifts out of sync with the hub.
   ========================================================================== */

(function () {
  'use strict';

  const strip   = document.getElementById('strip');
  const postsEl = document.getElementById('posts');
  const yearEl  = document.getElementById('year');

  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[c]));

  if (strip && typeof TOOLS !== 'undefined') {
    strip.innerHTML = TOOLS.map((t) => `
      <a class="strip__item" href="${esc(t.url)}" target="_blank" rel="noopener">
        <span class="strip__name">${esc(t.name)}</span>
        <span class="strip__cat">${esc((t.cats || [])[0] || '')}</span>
        ${t.module ? `<code class="strip__mod">${esc(t.module)}</code>` : ''}
      </a>`).join('');
  }

  /* Writing — data comes from posts.js, regenerated daily from the Medium
     RSS feed. If that file is missing or empty the section degrades to a
     single link out to Medium rather than rendering an empty list. */
  if (postsEl) {
    if (typeof POSTS !== 'undefined' && POSTS.length) {
      postsEl.innerHTML = POSTS.map((p) => `
        <li class="post">
          <a href="${esc(p.url)}" target="_blank" rel="noopener">
            <time datetime="${esc(p.iso)}">${esc(p.label)}</time>
            <span class="post__title">${esc(p.title)}</span>
            <svg class="icon post__arrow" aria-hidden="true"><use href="#i-link-external"></use></svg>
          </a>
        </li>`).join('');
    } else {
      postsEl.innerHTML = `
        <li class="post">
          <a href="https://medium.com/@markhunterorr" target="_blank" rel="noopener">
            <span class="post__title">Read the latest posts on Medium</span>
            <svg class="icon post__arrow" aria-hidden="true"><use href="#i-link-external"></use></svg>
          </a>
        </li>`;
    }
  }

  if (yearEl) yearEl.textContent = new Date().getFullYear();
})();
