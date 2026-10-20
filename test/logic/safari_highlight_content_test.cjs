const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const script = fs.readFileSync(path.join(__dirname,
  '../../ios/SafariHighlightExtension/Resources/content.js'), 'utf8');

function harness({ text = '你好 & café', paragraph = 'Before 你好 & café after.', editable = false, crossParagraph = false, nestedParagraphs = false } = {}) {
  const events = {};
  const timers = new Map();
  const elements = [];
  let timerId = 0;
  function element(tag) {
    const value = {
      tag, attributes: {}, events: {}, children: [], offsetWidth: 180, offsetHeight: 40,
      style: { setProperty(key, val) { this[key] = val; } },
      setAttribute(key, val) { this.attributes[key] = val; },
      removeAttribute(key) { delete this[key]; },
      append(...children) { this.children.push(...children); },
      addEventListener(key, callback) { this.events[key] = callback; },
      attachShadow() { return element('shadow'); },
    };
    elements.push(value);
    return value;
  }
  const block = { innerText: paragraph, querySelector: () => nestedParagraphs ? {} : null };
  const sourceElement = {
    closest(selector) {
      return selector === 'p, blockquote, li' ? block : editable ? {} : null;
    },
  };
  const startContainer = { nodeType: 3, parentElement: sourceElement };
  const endContainer = crossParagraph
    ? { nodeType: 3, parentElement: { closest: () => ({ innerText: 'Other paragraph' }) } }
    : startContainer;
  const selection = {
    rangeCount: 1, isCollapsed: false, toString: () => text,
    getRangeAt: () => ({
      startContainer, endContainer,
      commonAncestorContainer: { nodeType: 3, parentElement: sourceElement },
      getBoundingClientRect: () => ({ left: 30, top: 100, bottom: 130 }),
    }),
  };
  const window = {
    innerWidth: 390, innerHeight: 700, getSelection: () => selection,
    addEventListener() {},
  };
  window.top = window;
  const document = {
    documentElement: element('html'), createElement: element,
    createElementNS(namespace, tag) { return element(tag); },
    addEventListener(key, callback) { events[key] = callback; }, hidden: false,
  };
  vm.runInNewContext(script, {
    window, document, Node: { ELEMENT_NODE: 1 }, URLSearchParams,
    location: { protocol: 'https:', href: 'https://example.com/article?q=a%26b#section' },
    setTimeout(callback) { timers.set(++timerId, callback); return timerId; },
    clearTimeout(id) { timers.delete(id); },
  });
  function flush() {
    const pending = [...timers.values()]; timers.clear();
    pending.forEach(callback => callback());
  }
  return { events, selection, document, flush,
    host: elements.find(value => value.tag === 'div'),
    link: elements.find(value => value.tag === 'a') };
}

test('selection draft includes Unicode text, exact URL and paragraph', () => {
  const h = harness(); h.events.selectionchange(); h.flush();
  const url = new URL(h.link.href);
  assert.equal(url.protocol, 'yakihonne:');
  assert.equal(url.searchParams.get('text'), '你好 & café');
  assert.equal(url.searchParams.get('url'), 'https://example.com/article?q=a%26b#section');
  assert.equal(url.searchParams.get('context'), 'Before 你好 & café after.');
  assert.equal(h.host.style.display, 'block');
});
test('editable and oversized selections do not show the button', () => {
  for (const options of [{ editable: true }, { text: 'a'.repeat(4001) }, { text: '' }]) {
    const h = harness(options); h.events.selectionchange(); h.flush();
    assert.equal(h.host.style.display, 'none');
  }
});
test('tapping preserves the cached link while selection collapses', () => {
  const h = harness(); h.events.selectionchange(); h.flush();
  const href = h.link.href;
  h.link.events.pointerdown(); h.selection.isCollapsed = true;
  h.events.selectionchange(); h.flush();
  assert.equal(h.host.style.display, 'block');
  assert.equal(h.link.href, href);
  h.link.events.pointerup(); h.flush(); h.flush();
  assert.equal(h.host.style.display, 'none');
});
test('unrelated paragraph text is not sent', () => {
  const h = harness({ paragraph: 'unrelated' }); h.events.selectionchange(); h.flush();
  assert.equal(new URL(h.link.href).searchParams.has('context'), false);
});
test('compact button keeps its app-specific accessible label and decorative icon', () => {
  const h = harness();
  assert.equal(h.link.children[1].textContent, 'Highlight');
  assert.equal(h.link.children[0].attributes['aria-hidden'], 'true');
  assert.equal(h.link.attributes.title, 'Highlight in YakiHonne');
  assert.match(h.link.attributes['aria-label'], /YakiHonne/);
});
test('neighboring or nested paragraphs are never gathered as context', () => {
  for (const options of [{ crossParagraph: true }, { nestedParagraphs: true }]) {
    const h = harness(options); h.events.selectionchange(); h.flush();
    assert.equal(new URL(h.link.href).searchParams.has('context'), false);
  }
});
