// Prende il posto del vecchio service worker di Godot (tools/deploy_web.sh). Quello vecchio teneva
// in cache il gioco e lo serviva anche dopo un aggiornamento. Questo si installa subito, svuota le
// cache, si cancella e ricarica le pagine aperte: da lì il gioco arriva sempre dalla rete.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
	event.waitUntil((async () => {
		const keys = await caches.keys();
		await Promise.all(keys.map((k) => caches.delete(k)));
		await self.registration.unregister();
		const pages = await self.clients.matchAll({ type: 'window' });
		pages.forEach((c) => c.navigate(c.url));
	})());
});
