import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined;

if (key?.startsWith('sb_secret_')) {
  throw new Error('Use the publishable key here, never a secret key.');
}

/** Null when the site was built without Supabase settings (see .env.example). */
export const supabase =
  url && key
    ? createClient(url, key, {
        auth: { persistSession: true, autoRefreshToken: true },
      })
    : null;
