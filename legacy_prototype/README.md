# Legacy prototype (archived)

This is the original Flutter prototype, archived here for reference during the
Phase 0 rebuild (see the top-level README for the current architecture).

**Do not build on top of this code and do not reuse its data-layer wiring.**
It exists purely as a UX/UI reference for later phases. Specifically:

- All progress (`CurioState`) is in-memory and client-trusted - scores,
  answers, and rewards are computed and accepted on-device with no server
  authority. The rebuild's non-negotiable #1 principle is the opposite of
  this: server-authoritative everything.
- `resources/mmd_files` describes a **Firestore** data model and Cloud
  Functions boundary. The rebuild uses **Supabase** (Postgres, RLS, Edge
  Functions) instead - the collection model, in particular, does not apply.
- There's no offline sync queue, no content versioning, and no RLS/consent
  model - all five of the rebuild's non-negotiable principles are unmet here.

When later phases implement Squeeze, the Frostlands story, the parent
dashboard, etc. for real, it's reasonable to open the matching file here for
UI ideas (layout, copy, interaction shape) - just not for architecture or
data-access patterns.
