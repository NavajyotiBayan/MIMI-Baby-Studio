export default {
  async fetch(request) {
    const url = new URL(request.url);

    // This Worker is intended for the dedicated installer hostname:
    // mimibaby.navajyoti.online
    if (url.pathname !== "/" && url.pathname !== "") {
      return new Response("MIMI Baby Studio Installer", {
        status: 404,
        headers: { "Content-Type": "text/plain; charset=utf-8" }
      });
    }

    const installer =
      "https://raw.githubusercontent.com/NavajyotiBayan/MIMI-Baby-Studio/main/cloudflare-worker/public/installer.ps1";

    try {
      const response = await fetch(installer, { cf: { cacheTtl: 0, cacheEverything: false } });

      if (!response.ok) {
        return new Response("Unable to retrieve the MIMI Baby Studio installer.", {
          status: 502,
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "no-store"
          }
        });
      }

      return new Response(await response.text(), {
        status: 200,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store, no-cache, must-revalidate"
        }
      });
    } catch {
      return new Response("MIMI Baby Studio installer service is temporarily unavailable.", {
        status: 502,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store"
        }
      });
    }
  }
};
