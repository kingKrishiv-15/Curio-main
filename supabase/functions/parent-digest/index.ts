import { createClient } from "npm:@supabase/supabase-js@2.57.4";
import { createParentDigest } from "./digest.ts";

// The hourly database job authenticates with its dedicated cron secret.
Deno.serve(createParentDigest({
  env: (name) => Deno.env.get(name),
  createAdmin: (url, key) =>
    createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    }),
}));
