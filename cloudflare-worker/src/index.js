export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/mimibaby" || url.pathname === "/mimibaby/") {
      const asset = await env.ASSETS.fetch(new URL("/installer.ps1", request.url));
      return new Response(asset.body, {
        status: 200,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store, no-cache, must-revalidate",
          "X-Content-Type-Options": "nosniff"
        }
      });
    }

    return new Response("MIMI Baby Studio installer endpoint.\n", {
      status: 404,
      headers: { "Content-Type": "text/plain; charset=utf-8" }
    });
  }
};
