# MIMI Baby Studio — Cloudflare one-command installer

This Worker serves a PowerShell installer at:

```powershell
irm navajyoti.online/mimibaby | iex
```

## Before deployment

1. Create/push the `MIMI-Baby-Studio` repository to GitHub.
2. Open `public/installer.ps1`.
3. Change:

```powershell
$MimiDownloadUrl = 'https://github.com/CHANGE-ME/MIMI-Baby-Studio/archive/refs/heads/main.zip'
```

to your real GitHub repository archive URL.

## Cloudflare

The Worker project is configured for Workers Static Assets and a dashboard-managed route. The route should be:

```text
navajyoti.online/mimibaby
```

If the route is already configured in the Cloudflare dashboard, leave `routes` out of `wrangler.jsonc`; this prevents a later deploy from overwriting your dashboard route.

Deploy with current Wrangler:

```powershell
npm install
npx wrangler login
npx wrangler deploy
```

Cloudflare currently recommends `wrangler.jsonc` for new Worker projects. Routes can be managed in the dashboard under Worker → Settings → Domains & Routes → Add → Route. See the official Cloudflare documentation for current routing and deployment details.
