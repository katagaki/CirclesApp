import { SELF } from "cloudflare:test";
import { expect, it } from "vitest";

it("serves health", async () => {
  const response = await SELF.fetch("https://relay.test/health");
  expect(response.status).toBe(200);
});
