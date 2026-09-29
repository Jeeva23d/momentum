const CACHE = 'momentum-v4';
const CORE = ['./', './index.html', './manifest.webmanifest', './icon.svg'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting()).catch(() => {}));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  // Only ever touch same-origin requests. Cross-origin calls (e.g. the Supabase
  // cloud database) must go straight to the network untouched.
  if (url.origin !== self.location.origin) return;
  // Never cache the live database API — always go to network, fall back to cache when offline.
  if (url.pathname.startsWith('/api/')) {
    e.respondWith(fetch(e.request).catch(() => caches.match(e.request)));
    return;
  }
  // App shell + assets: cache-first, then update cache in background.
  // The page/app-shell (HTML) is NETWORK-FIRST so new versions show up immediately.
  // Falls back to the cached copy only when offline.
  const isPage = e.request.mode === 'navigate' ||
                 url.pathname === '/' ||
                 url.pathname.endsWith('.html');
  if (isPage) {
    e.respondWith(
      fetch(e.request).then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        return res;
      }).catch(() => caches.match(e.request).then(c => c || caches.match('./index.html')))
    );
    return;
  }

  // Other static assets (icon, manifest): cache-first, refresh in background.
  e.respondWith(
    caches.match(e.request).then(cached =>
      cached || fetch(e.request).then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        return res;
      }).catch(() => cached)
    )
  );
});
