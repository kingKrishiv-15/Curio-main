-- The learner's age, asked once during onboarding.
--
-- Nothing reads it yet. It is collected now so that games and briefs can be
-- matched to age later without asking every family again. It is optional:
-- learners created before this migration simply have no age.
alter table public.child_profiles
  add column if not exists age smallint check (age between 5 and 18);

-- Harmless where table-level grants already cover the column, and needed
-- where access to child_profiles is granted column by column.
grant select (age), insert (age), update (age) on public.child_profiles to authenticated;
