-- Run only after deploying parent-digest and setting its secrets.
-- First add curio_project_url and curio_cron_secret to Supabase Vault.
-- curio_cron_secret must equal the Edge Function CURIO_CRON_SECRET secret.
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;
do $$
begin
  if not exists(select 1 from vault.decrypted_secrets where name='curio_project_url') or
     not exists(select 1 from vault.decrypted_secrets where name='curio_cron_secret') then
    raise exception 'Configure curio_project_url and curio_cron_secret in Vault first';
  end if;
end $$;
select cron.schedule('curio-family-updates','5 * * * *',$job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name='curio_project_url') || '/functions/v1/parent-digest',
    headers := jsonb_build_object('Content-Type','application/json','x-curio-cron-secret',(select decrypted_secret from vault.decrypted_secrets where name='curio_cron_secret')),
    body := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
$job$);
