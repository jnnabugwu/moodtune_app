# App Links / Universal Links Plan (to add later)

1. Acquire domain (e.g., `app.moodtune.com`) and host HTTPS.
2. Set `SPOTIFY_APP_REDIRECT_URI` to `https://app.moodtune.com/spotify/callback` (keep custom scheme fallback `moodtune://spotify/callback`).
3. iOS: Host `apple-app-site-association` at `https://app.moodtune.com/.well-known/apple-app-site-association` with the app’s bundle ID and paths (`/spotify/callback`). Enable Associated Domains in Xcode (`applinks:app.moodtune.com`).
4. Android: Host `assetlinks.json` at `https://app.moodtune.com/.well-known/assetlinks.json` with the app’s SHA-256 and package name; add intent filter for App Links (`https://app.moodtune.com/spotify/callback`).
5. Update Spotify Dashboard redirect whitelist to include the HTTPS app link (and keep backend callback URL for server exchange).
6. In Flutter, prefer the HTTPS app link; keep the custom scheme as fallback in deep link handling.

