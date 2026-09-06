# MIMI Baby Studio — One-command installation

The application itself is kept from the supplied MIMI Baby Studio v2 project.

The new `cloudflare-worker` folder provides the public PowerShell installer endpoint.

## User command

```powershell
irm navajyoti.online/mimibaby | iex
```

## Installation flow

1. PowerShell downloads the current GitHub repository ZIP.
2. The archive is extracted to a temporary folder.
3. The existing `start.bat` is launched.
4. `start.bat` performs Administrator elevation when required.
5. MIMI is installed to `C:\MIMI Baby Studio`.
6. Existing Python/FFmpeg setup is preserved.
7. Existing background startup and browser-launch behavior is preserved.

## Required final configuration

The only project-specific value that cannot be safely guessed is the GitHub repository owner/name. Set `$MimiDownloadUrl` in:

`cloudflare-worker/public/installer.ps1`

Example:

```powershell
$MimiDownloadUrl = 'https://github.com/YOUR-USERNAME/MIMI-Baby-Studio/archive/refs/heads/main.zip'
```

Do not replace this with a guessed username. Use the exact repository URL after you create the GitHub repository.
