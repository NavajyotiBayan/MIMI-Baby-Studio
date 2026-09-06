# MIMI Baby Studio — Cloudflare one-command installer

This Worker serves the PowerShell installer at:

```powershell
irm navajyoti.online/mimibaby | iex
```

## GitHub source

The installer downloads the public GitHub repository:

```text
https://github.com/NavajyotiBayan/MIMI-Baby-Studio
```

The configured archive URL is:

```text
https://github.com/NavajyotiBayan/MIMI-Baby-Studio/archive/refs/heads/main.zip
```

## Cloudflare route

Configure this Worker route in the Cloudflare dashboard:

```text
navajyoti.online/mimibaby
```

The route is intentionally not declared in `wrangler.jsonc`, so your existing dashboard-managed route is not replaced by deployment.

## Deploy

From this directory:

```powershell
npm install
npx wrangler login
npx wrangler deploy
```

After deployment, verify the endpoint:

```powershell
irm navajyoti.online/mimibaby
```

It should return the PowerShell installer source as plain text.

Then the user can install MIMI with:

```powershell
irm navajyoti.online/mimibaby | iex
```
