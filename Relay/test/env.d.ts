declare namespace Cloudflare {
  interface Env extends import("../src/push").PushEnv {
    IDENTITY: DurableObjectNamespace<import("../src/identity").Identity>;
    ROOM: DurableObjectNamespace<import("../src/room").Room>;
  }
}
