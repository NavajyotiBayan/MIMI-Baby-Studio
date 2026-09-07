# MIMI Baby Studio Direct Installer

This folder contains the production `install.ps1` intended to be served by the Cloudflare Worker.

PowerShell command:

```powershell
irm https://mimibaby.navajyoti.online | iex
```

The installer downloads the current `main` branch archive from the official GitHub repository, validates the application, copies it to `C:\MIMI Baby Studio`, and runs the existing setup.

## GitHub placement

Copy `install.ps1` to the repository root:

`NavajyotiBayan/MIMI-Baby-Studio/install.ps1`

Then the Cloudflare Worker should fetch:

`https://raw.githubusercontent.com/NavajyotiBayan/MIMI-Baby-Studio/main/install.ps1`

The installer URL is intentionally separate from the application package so the Worker only needs to serve one text file.
