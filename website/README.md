# Curio website

The public site: home page, Privacy Policy, account deletion, and the family
dashboard where parents sign in to see progress and weekly reports. React +
Vite, one real HTML file per page (so `/privacy.html` and
`/delete-account.html`, linked from the Play Store listing, never move).

## Set up once

```bash
cd website
npm install
cp .env.example .env   # then fill in the Supabase URL and *publishable* key
```

## Work on it

```bash
npm run dev            # http://localhost:5173
```

Shared facts (contact email, Play Store link) live in `src/lib/site.ts`.

## Publish

**GitHub Pages** (serves the repo's `docs/` folder):

```bash
npm run build:pages    # rebuilds ../docs — commit and push it
```

Repo → Settings → Pages → Source: *Deploy from a branch*, branch `main`,
folder `/docs`. Custom domain: `curioeducation.co.in` (`public/CNAME` keeps it
across rebuilds).

**Vercel**: import the repo, set *Root Directory* to `website`, framework
*Vite*, and add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` as
environment variables. Vercel builds it on every push.

Only ever use the publishable key here — it's public by design. Never a
secret or service-role key.
