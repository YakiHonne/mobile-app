(() => {
  'use strict';
  if (window.top !== window || !/^https?:$/.test(location.protocol)) return;

  const spacing = 20;
  const host = document.createElement('div');
  host.style.cssText = 'all:initial!important;position:fixed!important;z-index:2147483647!important;display:none!important;';
  const shadow = host.attachShadow({ mode: 'closed' });
  const style = document.createElement('style');
  style.textContent = `
    a { display:inline-flex; align-items:center; gap:${spacing / 2.5}px;
      box-sizing:border-box; min-height:44px; padding:0 ${spacing / 1.5}px;
      border:1px solid rgba(0,0,0,.09); border-radius:300px;
      background:#fff; color:#1d1d1f; font:600 13px/1 system-ui,sans-serif;
      letter-spacing:-.1px; text-decoration:none;
      box-shadow:0 2px 5px rgba(0,0,0,.04),0 6px 20px rgba(0,0,0,.10);
      -webkit-user-select:none; user-select:none; -webkit-tap-highlight-color:transparent;
      white-space:nowrap; touch-action:manipulation;
      transition:background-color .15s ease,box-shadow .15s ease; }
    svg { width:16px; height:16px; flex:none; color:#ee7700; }
    svg,span { pointer-events:none; }
    a:active { background:#f4f4f4; box-shadow:0 2px 8px rgba(0,0,0,.08); }
    a:focus-visible { outline:2px solid #ee7700; outline-offset:${spacing / 5}px; }
    @media (prefers-color-scheme:dark) {
      a { background:#232326; color:#f5f5f7; border-color:rgba(255,255,255,.14);
        box-shadow:0 2px 5px rgba(0,0,0,.12),0 6px 20px rgba(0,0,0,.24); }
      a:active { background:#303034; }
    }
    @media (prefers-reduced-motion:reduce) { a { transition:none; } }
  `;
  const link = document.createElement('a');
  const icon = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  icon.setAttribute('viewBox', '0 0 24 24');
  icon.setAttribute('fill', 'none');
  icon.setAttribute('stroke', 'currentColor');
  icon.setAttribute('stroke-width', '1.8');
  icon.setAttribute('stroke-linecap', 'round');
  icon.setAttribute('stroke-linejoin', 'round');
  icon.setAttribute('aria-hidden', 'true');
  const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  path.setAttribute('d', 'm9 11 7-7 4 4-7 7-4-4Zm0 0-3 5 2 2 5-3M5 19h5M4 22h16');
  icon.append(path);
  const label = document.createElement('span');
  label.textContent = 'Highlight';
  link.append(icon, label);
  link.setAttribute('title', 'Highlight in YakiHonne');
  link.setAttribute('aria-label', 'Open selected text as a highlight draft in YakiHonne');
  shadow.append(style, link);
  document.documentElement.append(host);

  let pressingLink = false;
  let scheduled;
  function hide() {
    host.style.setProperty('display', 'none', 'important');
    link.removeAttribute('href');
  }
  function update() {
    if (pressingLink) return;
    const selection = window.getSelection();
    const text = selection ? selection.toString().trim() : '';
    if (!text || text.length > 4000 || !selection.rangeCount || selection.isCollapsed) {
      hide();
      return;
    }
    const range = selection.getRangeAt(0);
    const node = range.commonAncestorContainer;
    const element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
    if (!element || element.closest('input, textarea, [contenteditable]:not([contenteditable="false"])')) {
      hide();
      return;
    }
    const paragraphFor = (node) => {
      const element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
      return element ? element.closest('p, blockquote, li') : null;
    };
    const startBlock = paragraphFor(range.startContainer);
    const endBlock = paragraphFor(range.endContainer);
    // Never gather neighboring paragraphs from a common ancestor container.
    const block = startBlock && startBlock === endBlock &&
      !startBlock.querySelector('p, blockquote, li') ? startBlock : null;
    const paragraph = block ? (block.innerText || block.textContent || '').trim() : '';
    const sourceUrl = location.href;
    if (sourceUrl.length > 4000) { hide(); return; }
    const params = new URLSearchParams({ text, url: sourceUrl });
    if (paragraph.length <= 6000 && paragraph.includes(text)) params.set('context', paragraph);
    let href = 'yakihonne://highlight?' + params.toString();
    if (href.length > 24000) {
      params.delete('context');
      href = 'yakihonne://highlight?' + params.toString();
    }
    if (href.length > 24000) { hide(); return; }
    const rect = range.getBoundingClientRect();
    const viewport = window.visualViewport;
    const left = viewport ? viewport.offsetLeft : 0;
    const top = viewport ? viewport.offsetTop : 0;
    const width = viewport ? viewport.width : window.innerWidth;
    const height = viewport ? viewport.height : window.innerHeight;
    if (rect.bottom < top || rect.top > top + height) { hide(); return; }
    link.href = href;
    host.style.setProperty('display', 'block', 'important');
    // Prefer below the quote, clear of Safari's menu above the selection.
    const x = Math.max(left + spacing / 2, Math.min(rect.left, left + width - host.offsetWidth - spacing / 2));
    const y = Math.max(top + spacing / 2, Math.min(rect.bottom + spacing, top + height - host.offsetHeight - spacing));
    host.style.setProperty('left', x + 'px', 'important');
    host.style.setProperty('top', y + 'px', 'important');
  }
  function schedule() {
    clearTimeout(scheduled);
    scheduled = setTimeout(update, 180);
  }
  // Cache the href before tapping changes the selection. Navigation stays a
  // direct user gesture, allowing Safari to offer its normal app-open prompt.
  link.addEventListener('pointerdown', () => { pressingLink = true; });
  link.addEventListener('pointercancel', () => { pressingLink = false; schedule(); });
  link.addEventListener('pointerup', () => {
    setTimeout(() => { pressingLink = false; schedule(); }, 300);
  });
  document.addEventListener('selectionchange', schedule);
  document.addEventListener('scroll', schedule, { passive: true, capture: true });
  window.addEventListener('resize', schedule, { passive: true });
  window.visualViewport?.addEventListener('resize', schedule, { passive: true });
  window.visualViewport?.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('pagehide', hide);
  document.addEventListener('visibilitychange', () => {
    pressingLink = false;
    if (document.hidden) hide(); else schedule();
  });
  schedule();
})();
