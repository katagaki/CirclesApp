import { Room } from "./room";

export { Room };

const ROOM_PATH = /^\/r\/([0-9a-f]{32})$/;
const HOMEPAGE = "https://github.com/katagaki/CirclesRelay";

export interface Env {
  ROOM: DurableObjectNamespace;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/health") return new Response("ok");
    if (url.pathname === "/" && url.search === "") return Response.redirect(HOMEPAGE, 302);
    const match = ROOM_PATH.exec(url.pathname);
    if (!match) return new Response("bad request", { status: 400 });
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("expected websocket", { status: 400 });
    }
    return env.ROOM.get(env.ROOM.idFromName(match[1])).fetch(request);
  },
};
