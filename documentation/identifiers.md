# Identifiers: `id` vs `reference_xid`

Every row has two identifiers. Use each where it belongs.

- **`id`** (integer primary key) — internal. Joins, foreign keys, lookups, associations, queries.
- **`reference_xid`** (UUIDv7, unique) — public. The only identifier that crosses the network: URLs, request bodies, response bodies.

## Rules

- In a URL, request body, or response body → `reference_xid`.
- Used to look up, join, filter, or associate → `id`.
- Foreign keys are **always** `id` (`user_id`, `goal_id`, `parent_id`). Never store a `reference_xid` as an FK.
- Never expose `id` or any FK in a response.
- A related resource is exposed by its `reference_xid` (e.g. `goal_reference_xid`), never its FK.
- Don't send out `reference_xid` as `id` in a response. Be transparent
- Never accept `id` in a request body. Always accept `reference_xid` and resolve it to `id` internally.

## Where it lives (the whole pattern)

- **Inbound** — the context resolves the public ref, scoped, at the boundary: `get_goal!(scope, reference_xid)`. After that you hold the record and work with its `id`.
- **Outbound** — the JSON view emits `reference_xid` and hides `id`/FKs.

The layers in between speak `id` only.

## Why

`id` is sequential: exposing it lets a user enumerate others' data (`id + 1`) and leaks row counts/growth. `reference_xid` is opaque and unguessable. Scoping still applies on top — a leaked ref from another user's scope still 404s.
