# CirclesRelay

Store-and-forward relay for the shared Buys feature of the CiRCLES apps: one Cloudflare Worker, one Durable Object per room, and WebSockets. The wire protocol both apps speak, over the relay and over Bluetooth, is documented byte by byte in [PROTOCOL.html](PROTOCOL.html).

## Develop and deploy

```bash
npm install && npm test
npm run dev
npx wrangler deploy --env staging
npx wrangler deploy --env production
```

CI deploys on published GitHub Releases: a prerelease goes to staging, a full release to production, using a `CLOUDFLARE_API_TOKEN` secret scoped to Edit Cloudflare Workers. There are no Worker secrets — room keys arrive from clients at runtime and live only in each object's storage.
