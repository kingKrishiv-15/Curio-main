import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { renderReport, type WeeklySummary } from '../_shared/reports.ts';

// Server-only endpoint: a dedicated cron secret, never a client API key.
Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', {status:405});
  const cronSecret = Deno.env.get('CURIO_CRON_SECRET');
  if (!cronSecret || req.headers.get('x-curio-cron-secret') !== cronSecret) return new Response('Unauthorized', {status:401});
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return new Response('Backend not configured', {status:503});
  const db = createClient(url, key, {auth:{persistSession:false,autoRefreshToken:false}});
  const {error: queueError} = await db.rpc('queue_family_updates');
  if (queueError) { console.error('Could not queue family updates', queueError.code); return new Response('Queue unavailable', {status:500}); }
  const apiKey = Deno.env.get('RESEND_API_KEY');
  const sender = Deno.env.get('CURIO_EMAIL_FROM');
  const appUrl = Deno.env.get('CURIO_APP_URL');
  if (!apiKey || !sender || !appUrl?.startsWith('https://')) {
    // In-app generation works without email credentials; don't claim mail yet.
    return Response.json({inbox:'updated',email:'not_configured'}, {status:503});
  }
  const {data: jobs, error: claimError} = await db.rpc('claim_parent_emails');
  if (claimError) return new Response('Outbox unavailable', {status:500});
  let sent=0,failed=0;
  for (const job of jobs ?? []) {
    try {
      const {data: settings,error: settingsError}=await db.from('family_settings').select('weekly_email_enabled').eq('parent_id',job.parent_id).single();
      if (settingsError) throw new Error('preferences_unavailable');
      if (!settings.weekly_email_enabled) { await db.from('email_outbox').update({status:'cancelled'}).eq('id',job.id); continue; }
      const {data: account,error: accountError}=await db.auth.admin.getUserById(job.parent_id);
      if (accountError || !account.user?.email_confirmed_at || !account.user?.email) throw new Error('verified_recipient_unavailable');
      const {data: report,error: reportError}=await db.from('parent_reports').select('summary').eq('id',job.report_id).eq('parent_id',job.parent_id).single();
      if (reportError) throw new Error('report_unavailable');
      const content=renderReport(report.summary as WeeklySummary, appUrl);
      const response=await fetch('https://api.resend.com/emails', {method:'POST', signal:AbortSignal.timeout(15000),headers:{Authorization:`Bearer ${apiKey}`,'Content-Type':'application/json','Idempotency-Key':`curio-report-${job.id}`},body:JSON.stringify({from:sender,to:[account.user.email],...content})});
      if(!response.ok) throw new Error(`email_provider_${response.status}`);
      const result=await response.json();
      const {error: saveError}=await db.from('email_outbox').update({status:'sent',sent_at:new Date().toISOString(),provider_id:result.id,last_error:null}).eq('id',job.id);
      if(saveError) throw new Error('delivery_receipt_not_saved');
      sent++;
    } catch(error) {
      failed++;
      const reason=error instanceof Error ? error.message : 'delivery_failed';
      await db.from('email_outbox').update({status:'failed',last_error:reason.slice(0,120)}).eq('id',job.id);
    }
  }
  return Response.json({sent,failed});
});
