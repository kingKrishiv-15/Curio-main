import assert from "node:assert/strict";
import { createServer } from "node:http";
import { test } from "node:test";
import { createParentDigest } from "./digest.ts";

const env: Record<string, string> = {
  CURIO_CRON_SECRET: "local-schedule-secret",
  SUPABASE_URL: "http://localhost",
  SUPABASE_SERVICE_ROLE_KEY: "local-service-key",
  RESEND_API_KEY: "local-mail-key",
  CURIO_EMAIL_FROM: "Curio <reports@example.test>",
  CURIO_APP_URL: "https://curio.example.test/",
};

const report = {
  week_start: "2026-11-02",
  week_end: "2026-11-08",
  learners: [
    {
      name: "Alex",
      activities: 6,
      practice_days: 3,
      total_xp: 620,
      discoveries: 5,
      skills: { Memory: .35, English: .47 },
    },
  ],
};

type Parent = { id: string; enabled: boolean; verified: boolean };
type OutboxUpdate = {
  status: string;
  provider_id?: string;
  last_error?: string;
};
function database(parents: Parent[], failFirstReceipt = false) {
  const calls: string[] = [];
  const outbox = new Map<string, OutboxUpdate>();
  const client = {
    async rpc(name: string) {
      calls.push(name);
      const data = name === "claim_parent_emails"
        ? parents.filter((parent) =>
          !["sent", "cancelled"].includes(outbox.get(parent.id)?.status ?? "")
        )
          .map((parent) => ({
            id: parent.id,
            parent_id: parent.id,
            report_id: `report-${parent.id}`,
          }))
        : 1;
      return { data, error: null };
    },
    auth: {
      admin: {
        async getUserById(id: string) {
          const parent = parents.find((row) => row.id === id)!;
          return {
            data: {
              user: {
                email: `${id}@example.test`,
                email_confirmed_at: parent.verified ? "2026-11-01" : null,
              },
            },
            error: null,
          };
        },
      },
    },
    from(table: string) {
      const where = new Map<string, string>();
      const query = {
        eq(column: string, value: string) {
          where.set(column, value);
          return query;
        },
        async single() {
          const parent = parents.find((row) =>
            row.id === where.get("parent_id")
          )!;
          if (table === "parent_reports") {
            assert.equal(where.get("id"), `report-${parent.id}`);
            return { data: { summary: report }, error: null };
          }
          assert.equal(table, "family_settings");
          return {
            data: { weekly_email_enabled: parent.enabled },
            error: null,
          };
        },
      };
      return {
        select: () => query,
        update: (value: OutboxUpdate) => ({
          async eq(column: string, id: string) {
            assert.equal(table, "email_outbox");
            assert.equal(column, "id");
            if (failFirstReceipt && value.status === "sent") {
              failFirstReceipt = false;
              return { error: { code: "local_test_unavailable" } };
            }
            outbox.set(id, value);
            return { error: null };
          },
        }),
      };
    },
  };
  type Admin = ReturnType<
    Parameters<typeof createParentDigest>[0]["createAdmin"]
  >;
  return { calls, outbox, createAdmin: () => client as unknown as Admin };
}

function cron(secret = env.CURIO_CRON_SECRET) {
  return new Request("http://localhost/parent-digest", {
    method: "POST",
    headers: { "x-curio-cron-secret": secret },
  });
}

test("only the scheduler can run delivery; missing mail configuration still queues inbox reports", async () => {
  const db = database([]);
  const run = createParentDigest({
    ...db,
    env: (key) => key === "RESEND_API_KEY" ? undefined : env[key],
    sendFetch: async () => {
      throw new Error("Mail transport should stay idle");
    },
  });
  assert.equal((await run(cron("wrong-secret"))).status, 401);
  assert.equal(
    (await run(new Request("http://localhost/parent-digest"))).status,
    405,
  );
  assert.deepEqual(db.calls, []);
  const response = await run(cron());
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), {
    inbox: "updated",
    email: "not_configured",
  });
  assert.deepEqual(db.calls, ["queue_family_updates"]);
});

test("a retry writes one weekly email to the local inbox and honours consent and verification", async (t) => {
  const inbox = new Map<string, Record<string, unknown>>();
  const providerRequests: string[] = [];
  const receiver = createServer(async (request, response) => {
    let raw = "";
    for await (const part of request) raw += part;
    const idempotencyKey = String(request.headers["idempotency-key"]);
    providerRequests.push(idempotencyKey);
    if (!inbox.has(idempotencyKey)) inbox.set(idempotencyKey, JSON.parse(raw));
    response.setHeader("Content-Type", "application/json");
    response.end(JSON.stringify({ id: "local-delivery-id" }));
  });
  await new Promise<void>((resolve, reject) => {
    receiver.once("error", reject);
    receiver.listen(0, "127.0.0.1", resolve);
  });
  t.after(() => receiver.close());
  const address = receiver.address();
  assert.ok(address && typeof address !== "string");

  const db = database([
    { id: "subscribed", enabled: true, verified: true },
    { id: "unsubscribed", enabled: false, verified: true },
    { id: "unverified", enabled: true, verified: false },
  ], true);
  const run = createParentDigest({
    ...db,
    env: (key) => env[key],
    sendFetch: (destination, options) => {
      assert.equal(destination, "https://api.resend.com/emails");
      assert.equal(options?.method, "POST");
      return fetch(`http://127.0.0.1:${address.port}/emails`, options);
    },
  });

  const first = await run(cron());
  assert.equal(first.status, 502);
  assert.deepEqual(await first.json(), { sent: 0, failed: 2, cancelled: 1 });
  assert.equal(db.outbox.get("unsubscribed")?.status, "cancelled");
  assert.equal(
    db.outbox.get("unverified")?.last_error,
    "verified_recipient_unavailable",
  );
  assert.equal(
    db.outbox.get("subscribed")?.last_error,
    "delivery_receipt_not_saved",
  );

  const retry = await run(cron());
  assert.deepEqual(await retry.json(), { sent: 1, failed: 1, cancelled: 0 });
  assert.deepEqual(providerRequests, [
    "curio-report-subscribed",
    "curio-report-subscribed",
  ]);
  assert.equal(inbox.size, 1);
  const delivered = inbox.get("curio-report-subscribed")!;
  assert.deepEqual(delivered.to, ["subscribed@example.test"]);
  assert.match(String(delivered.subject), /Your Curio week/);
  assert.match(String(delivered.text), /Memory: 35%/);
  assert.match(String(delivered.html), /Alex/);
  assert.equal(db.outbox.get("subscribed")?.provider_id, "local-delivery-id");
});

test("a provider success without a delivery ID remains retryable", async () => {
  const db = database([{ id: "subscribed", enabled: true, verified: true }]);
  const run = createParentDigest({
    ...db,
    env: (key) => env[key],
    sendFetch: async () => Response.json({}),
  });
  const response = await run(cron());
  assert.equal(response.status, 502);
  assert.deepEqual(db.outbox.get("subscribed"), {
    status: "failed",
    last_error: "invalid_provider_receipt",
  });
});
