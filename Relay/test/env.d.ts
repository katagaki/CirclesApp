declare namespace Cloudflare {
  interface Env {
    ROOM: DurableObjectNamespace<import("../src/room").Room>;
  }
}
