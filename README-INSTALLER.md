# MIMI Baby Studio — One-command installation

MIMI Baby Studio can be installed on Windows with:

```powershell
irm navajyoti.online/mimibaby | iex
```

The application remains the supplied MIMI Baby Studio v2 project. The `cloudflare-worker` folder adds the Cloudflare Worker endpoint that serves the PowerShell installer.

## Installation flow

1. PowerShell requests `navajyoti.online/mimibaby`.
2. Cloudflare Worker returns `installer.ps1` as plain text.
3. PowerShell downloads the current `main` branch ZIP from GitHub.
4. The ZIP is extracted to a temporary directory.
5. The existing `start.bat` is launched.
6. `start.bat` handles Administrator elevation, Python/FFmpeg setup, installation to `C:\MIMI Baby Studio`, background startup, and browser launch.

## GitHub repository

The installer is configured for:

```text
https://github.com/NavajyotiBayan/MIMI-Baby-Studio
```

The download URL used by the installer is:

```powershell
$MimiDownloadUrl = 'https://github.com/NavajyotiBayan/MIMI-Baby-Studio/archive/refs/heads/main.zip'
```

Keep the repository public if you want the installer to download it without GitHub authentication.

## Cloudflare route

Create a Worker route:

```text
navajyoti.online/mimibaby
```

The Worker project intentionally does not define the route in `wrangler.jsonc`, because the route is managed in the Cloudflare dashboard.

## Deploy the Worker

From `cloudflare-worker`:

```powershell
npm install
npx wrangler login
npx wrangler deploy
```

Then test:

```powershell
irm navajyoti.online/mimibaby
```

It should output the PowerShell installer text. After that, the full install command is:

```powershell
irm navajyoti.online/mimibaby | iex
```
