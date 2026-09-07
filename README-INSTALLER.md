# MIMI Baby Studio — One-command installer

The public installer command is:

```powershell
irm https://mimibaby.navajyoti.online | iex
```

The custom domain is expected to be backed by a Cloudflare Worker that returns the repository's root `install.ps1` as plain text.

`install.ps1` then:

1. Queries the latest GitHub Release for `NavajyotiBayan/MIMI-Baby-Studio`.
2. Finds the `MIMI-Baby-Studio-*-Setup.exe` asset.
3. Downloads that Windows installer to a temporary directory.
4. Starts the installer.
5. Lets the normal Windows installer handle installation/elevation.

This keeps the public command short while keeping release binaries out of the source repository.

## Cloudflare Worker requirement

The Worker only needs to return the current contents of `install.ps1` for `/` and can reject other paths. No application files or Windows binaries should be stored in the Worker.
