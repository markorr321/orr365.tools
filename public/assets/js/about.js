/* ==========================================================================
   orr365.tools — about page
   Renders the compact tools strip from the shared TOOLS data in tools.js,
   so the About page never drifts out of sync with the hub.
   ========================================================================== */

(function () {
  'use strict';

  const strip  = document.getElementById('strip');
  const yearEl = document.getElementById('year');

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

  if (yearEl) yearEl.textContent = new Date().getFullYear();
})();
