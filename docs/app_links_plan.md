# App Links / Universal Links Plan (to add later)

Domain: **`getmoodtune.com`** (registered on Vercel, Hobby team `jnnabugwus-projects`). The static site is [jnnabugwu/getmoodtune-site](https://github.com/jnnabugwu/getmoodtune-site); pushes to its `main` deploy automatically, and `www.getmoodtune.com` redirects permanently (308) to the apex. We do **not** own `moodtune.com`, `moodtune.io` or `moodtune.app`, so never point links at them.

1. ~~Acquire domain and host HTTPS.~~ Done: `https://getmoodtune.com`.
2. Set `SPOTIFY_APP_REDIRECT_URI` to `https://getmoodtune.com/spotify/callback` (keep custom scheme fallback `moodtune://spotify/callback`).
3. iOS: Add `.well-known/apple-app-site-association` (no file extension) to getmoodtune-site with appIDs `UXZV3C926U.com.jmagic.moodtune` (plus `.stg` / `.dev` if those flavors need links) and paths (`/spotify/callback`). Enable Associated Domains in Xcode (`applinks:getmoodtune.com`).
4. Android: Add `.well-known/assetlinks.json` to getmoodtune-site with package `com.jmagic.moodtune` (and `.stg` / `.dev`) and each signing key's SHA-256, including the Play App Signing key once the app is on Play. Add an intent filter for App Links (`https://getmoodtune.com/spotify/callback`).
   - The site's `vercel.json` already serves `/.well-known/*` as `application/json`.
5. Update Spotify Dashboard redirect whitelist to include the HTTPS app link (and keep backend callback URL for server exchange).
6. In Flutter, prefer the HTTPS app link; keep the custom scheme as fallback in deep link handling.
