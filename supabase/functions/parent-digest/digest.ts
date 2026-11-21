import type { SupabaseClient } from "npm:@supabase/supabase-js@2.57.4";
import { renderReport, type WeeklySummary } from "../_shared/reports.ts";

type DigestDependencies = {
  env: (name: string) => string | undefined;
  createAdmin: (url: string, serviceRoleKey: string) => SupabaseClient;
  sendFetch?: typeof fetch;
};

function secureUrl(value: string | undefined): string | undefined {
  if (!value) return;
  try {
    const url = new URL(value);
    if (url.protocol === "https:") return url.href;
  } catch {
    // Delivery waits for a valid URL that the parent can open.
  }
}

export function createParentDigest({
  env,
  createAdmin,
  sendFetch = fetch,
}: DigestDependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }
    const cronSecret = env("CURIO_CRON_SECRET");
    if (
      !cronSecret || request.headers.get("x-curio-cron-secret") !== cronSecret
    ) {
      return new Response("Unauthorized", { status: 401 });
    }
    const url = env("SUPABASE_URL");
    const key = env("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !key) {
      return new Response("Backend not configured", { status: 503 });
    }

    const db = createAdmin(url, key);
    const { error: queueError } = await db.rpc("queue_family_updates");
    if (queueError) {
      console.error("Could not queue family updates", queueError.code);
      return new Response("Queue unavailable", { status: 500 });
    }
    const apiKey = env("RESEND_API_KEY");
    const sender = env("CURIO_EMAIL_FROM");
    const appUrl = secureUrl(env("CURIO_APP_URL"));
    if (!apiKey || !sender || !appUrl) {
      return Response.json({ inbox: "updated", email: "not_configured" }, {
        status: 503,
      });
    }
    const mail = { apiKey, sender, appUrl };

    const { data: jobs, error: claimError } = await db.rpc(
      "claim_parent_emails",
    );
    if (claimError) return new Response("Outbox unavailable", { status: 500 });

    let sent = 0;
    let failed = 0;
    let cancelled = 0;
    let nextSendAt = 0;

    async function deliver(
      job: { id: string; parent_id: string; report_id: string },
    ) {
      try {
        const [
          { data: account, error: accountError },
          { data: report, error: reportError },
        ] = await Promise.all([
          db.auth.admin.getUserById(job.parent_id),
          db.from("parent_reports").select("summary").eq("id", job.report_id)
            .eq("parent_id", job.parent_id).single(),
        ]);
        if (
          accountError || !account.user?.email_confirmed_at ||
          !account.user.email
        ) {
          throw new Error("verified_recipient_unavailable");
        }
        if (reportError || !report) throw new Error("report_unavailable");
        const content = renderReport(
          report.summary as WeeklySummary,
          mail.appUrl,
        );

        const { data: settings, error: settingsError } = await db.from(
          "family_settings",
        )
          .select("weekly_email_enabled").eq("parent_id", job.parent_id)
          .single();
        if (settingsError || !settings) {
          throw new Error("preferences_unavailable");
        }
        if (!settings.weekly_email_enabled) {
          const { error } = await db.from("email_outbox")
            .update({ status: "cancelled", last_error: null }).eq("id", job.id);
          if (error) throw new Error("cancellation_not_saved");
          cancelled++;
          return;
        }

        // Space provider requests across the batch. Slow requests can run
        // concurrently without blocking delivery of the rest of the batch.
        const now = Date.now();
        const sendAt = Math.max(now, nextSendAt);
        nextSendAt = sendAt + 550;
        if (sendAt > now) {
          await new Promise((resolve) => setTimeout(resolve, sendAt - now));
        }
        const response = await sendFetch("https://api.resend.com/emails", {
          method: "POST",
          signal: AbortSignal.timeout(15000),
          headers: {
            Authorization: `Bearer ${mail.apiKey}`,
            "Content-Type": "application/json",
            "Idempotency-Key": `curio-report-${job.id}`,
          },
          body: JSON.stringify({
            from: mail.sender,
            to: [account.user.email],
            ...content,
          }),
        });
        if (!response.ok) throw new Error(`email_provider_${response.status}`);
        const receipt = await response.json();
        if (typeof receipt?.id !== "string" || !receipt.id.trim()) {
          throw new Error("invalid_provider_receipt");
        }

        const { error } = await db.from("email_outbox").update({
          status: "sent",
          sent_at: new Date().toISOString(),
          provider_id: receipt.id,
          last_error: null,
        }).eq("id", job.id);
        if (error) throw new Error("delivery_receipt_not_saved");
        sent++;
      } catch (error) {
        failed++;
        const reason =
          error instanceof Error && /^[a-z0-9_]+$/.test(error.message)
            ? error.message
            : "delivery_failed";
        const { error: saveError } = await db.from("email_outbox")
          .update({ status: "failed", last_error: reason }).eq("id", job.id);
        if (saveError) {
          console.error("Could not record email failure", saveError.code);
        }
      }
    }

    // A provider timeout must not use the cron request's whole time budget
    // for the first few emails and strand the remaining claimed jobs.
    const batch = jobs ?? [];
    for (let start = 0; start < batch.length; start += 5) {
      await Promise.all(batch.slice(start, start + 5).map(deliver));
    }
    return Response.json({ sent, failed, cancelled }, {
      status: failed ? 502 : 200,
    });
  };
}
