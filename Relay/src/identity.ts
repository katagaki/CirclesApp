import { DurableObject } from "cloudflare:workers";
import { type AttestEnv, type Enrolled, type Verified, verifyAttestation } from "./attest";

export class Identity extends DurableObject<AttestEnv> {
  async enroll(verified: Extract<Verified, { ok: true }>): Promise<boolean> {
    return this.ctx.blockConcurrencyWhile(async () => {
      if (await this.ctx.storage.get("enrolled")) return false;
      await this.ctx.storage.put("enrolled", verified);
      return true;
    });
  }

  async authenticate(evidence: unknown, clientDataHash: Uint8Array): Promise<Verified> {
    return this.ctx.blockConcurrencyWhile(async () => {
      const enrolled = await this.ctx.storage.get<Enrolled>("enrolled");
      if (!enrolled) return { ok: false, reason: "device is not enrolled" };
      const result = await verifyAttestation(this.env, evidence, clientDataHash, enrolled);
      if (result.ok) await this.ctx.storage.put("enrolled", result);
      return result;
    });
  }
}
