declare namespace Cloudflare {
  interface Env extends import("../src/push").PushEnv {
    ROOM: DurableObjectNamespace<import("../src/room").Room>;
  }
}
