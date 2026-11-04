declare namespace Cloudflare {
  interface Env extends import("../src/push").PushEnv {
    IMAGES: R2Bucket;
    IDENTITY: DurableObjectNamespace<import("../src/identity").Identity>;
    ROOM: DurableObjectNamespace<import("../src/room").Room>;
  }
}
