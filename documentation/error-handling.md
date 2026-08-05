# Error handling

How this API turns a failure into an HTTP response. Covers every 4xx/5xx JSON body; it does not
cover crash recovery or supervision.

> Decided 2026-08-02 while implementing time entries. Checked against the Phoenix, Ecto and Plug
> docs, RFC 9110, and an audit of a mature enterprise Phoenix codebase. Sources at the bottom.

## Context

Every endpoint has to answer the same two questions: _which status?_ and _who decides?_ Answer them
per endpoint and the answers drift. The enterprise codebase we audited had no single translation
layer, so each controller chose its own status at the call site. The result, measured: four
different JSON error shapes live at once, 93% of errors collapsed into 422 regardless of cause, and
the same domain condition returning 409 in one controller and 422 in another.

None of that was a bad decision at the time — it's what happens when the convention is implicit.
This document makes ours explicit so the next endpoint inherits it instead of re-deriving it.

## Choosing a status

| What's wrong                                           | Status | Returned as                           | Rendered by                                 |
| ------------------------------------------------------ | ------ | ------------------------------------- | ------------------------------------------- |
| Body or params fail the OpenAPI schema                 | 422    | rejected before the action runs       | `ValidationErrorPlug`                       |
| A field value is invalid                               | 422    | `{:error, changeset}`                 | `ChangesetJSON`                             |
| Resource doesn't exist, or isn't in this scope         | 404    | `get_x!` raises `Ecto.NoResultsError` | `ErrorJSON`, via `Plug.Exception`           |
| The resource's **current state** forbids the operation | 409    | `{:error, :some_atom}`                | `ErrorJSON` `409.json`, with a `code`       |
| Not authenticated                                      | 401    | a router plug halts                   | `user_auth.ex` — never reaches the fallback |
| Authenticated but not allowed                          | 403    | `{:error, :forbidden}`                | `ErrorJSON`                                 |
| Anything unmatched                                     | 500    | the catch-all clause, logged          | `ErrorJSON`                                 |

> **409 or 422?** If fixing something _else_ — stopping a running timer, deleting a subtask — makes
> the byte-identical request succeed, it's **409**. If the request itself has to change, it's **422**.

Worked examples. `POST /tasks/:id/time_entries` on a task that has subtasks is **409**: the body is
perfectly valid, the task is the problem, and deleting the subtask makes the same request work. The
same request missing `started_at` is **422**: no amount of changing the task helps.

## How an error travels

Each layer has exactly one job.

1. **The context** returns `{:ok, result}` or `{:error, changeset | :some_atom}`. It never picks a
   status, never formats a message, and never knows it is being called over HTTP.
2. **The controller** is a bare `with` — no `else` clause, no `put_status` on the failure path. If
   the action returns anything that isn't a `Plug.Conn`, Phoenix hands it to the fallback.
3. **`FallbackController`** is the _only_ place an error value becomes a status. Every controller
   declares `action_fallback BrekitdownWeb.FallbackController`.
4. **A JSON view** renders the body: `ChangesetJSON` for changesets, `ErrorJSON` for everything else.

Four things can produce an error body. Knowing all four matters, because changing the error envelope
means changing all of them:

- `ValidationErrorPlug` — request rejected by `OpenApiSpex.Plug.CastAndValidate` before the action.
- `FallbackController` → `ChangesetJSON` / `ErrorJSON` — the normal path.
- `Plug.Exception` — a raised `Ecto.*` error, rendered through the endpoint's `render_errors` config
  (`config/config.exs:31`). No fallback clause is involved.
- `user_auth.ex` — the 401 halt.

**Why 401 is the odd one out.** A plug must always return a `Plug.Conn`, so
`require_authenticated_user/2` cannot hand `{:error, :unauthorized}` to `action_fallback` the way a
controller action can. It writes the same envelope by hand instead — see the comment at
`lib/brekitdown_web/user_auth.ex:55`. `{:error, :unauthorized}` still exists in the fallback, for
actions that need it.

## Decisions

### 1. Status is chosen by what is defective, not by what's convenient

**Decision.** 409 when the target resource's current state forbids the operation. 422 when the
request content itself can't be processed. Apply the discriminator above; don't reach for whichever
status is easier to return.

**Why.** RFC 9110 splits them cleanly: §15.5.10 defines 409 as _"a conflict with the current state
of the target resource… the user might be able to resolve the conflict and resubmit the request"_,
while §15.5.21 defines 422 as the server being _"unable to process the contained instructions"_ —
the request **content** is the defective thing. MDN adds the practical test: a 422 means repeating
the request unmodified fails identically. That's false for a state conflict. There's precedent
inside our own dependency tree, too — `phoenix_ecto` maps `Ecto.StaleEntryError` to 409.

**Cost.** 422 is the free path: any changeset error produces one with no extra code. Every 409 costs
an explicit guard in the context plus a clause in the fallback. And because generator-driven APIs
funnel almost everything into 422, a frontend developer may not expect a 409 — which is what
decision 3 exists to soften.

### 2. Every atom → status mapping lives in `FallbackController`

**Decision.** One file maps error values to statuses. Controllers never call `put_status` on a
failure path, and there is no shared render-helper that controllers call.

**Why.** This is precisely what `action_fallback` is for — the Phoenix docs describe it as a way to
_"translate common domain data structures into a valid `%Plug.Conn{}` response"_, with _"a single
fallback module"_ for values that cross multiple boundaries. Keeping it in one place is what makes
"change how we report conflicts" a one-file edit, and what keeps controller actions short enough to
read in one glance.

**Cost.** No compiler help. A context that returns a new error atom with no matching clause silently
becomes a 500. The catch-all at `fallback_controller.ex:22` logs the reason, which is what makes
that survivable rather than invisible — but it is caught at runtime, not compile time. The fallback
is also a shared file every feature has to touch.

### 3. Conflict responses carry a stable machine-readable `code`

**Decision.** A 409 body is `{"errors": {"code": "…", "detail": "…"}}`. Both keys are required, and
they are not interchangeable:

- **`detail` fully explains the conflict on its own.** A consumer displays it verbatim and must
  never need `code` plus this documentation to learn what happened. Copy is an API deliverable —
  never ship a placeholder, and never lean on `code` as an excuse to be terse.
- **`detail` states the conflict and stops there — no remedies** (decided 2026-08-05). Naming the
  entity, its state, and the constraint is what RFC 9110 asks for; what the caller should do about it
  is the client's call. "This task has subtasks, so time cannot be logged on it directly." is
  complete — "directly" plus "has subtasks" leaves only one place for the time to go, so spelling out
  "log it on a subtask instead" restates an inference the caller has already made. Suggested next
  steps also presuppose a UI flow and rot with product behavior: "Stop it before starting another."
  is wrong for half of `entry_already_running`'s callers, since both create and un-stop raise it. No
  exceptions means no per-message argument about whether a given remedy is timeless enough.
- **`code` is a stable snake_case identifier**, there so a consumer _can_ branch on the reason or
  substitute its own wording. It is additive convenience, not the explanation.

Other statuses carry `detail` only.

**Why.** RFC 9110 says a 409 _"SHOULD generate content that includes enough information for a user
to recognize the source of the conflict"_, and a bare status can't. Time entries alone ship two
distinct 409s — `not_a_leaf_task` and `entry_already_running` — on the same endpoint. Without a code
a consumer that wants to branch has to pattern-match on prose, which breaks the moment the copy is
improved; without self-sufficient `detail`, every consumer has to build a code→copy table before it
can show the user anything.

**Where it lives.** `BrekitdownWeb.Schemas.ConflictError` (`required: [:code, :detail]`) is the
declared response schema for every `conflict:` — not `Schemas.Error`, which declares `detail` only.
OpenApiSpex tolerates undeclared keys, so `Error` would let a 409 validate while publishing a spec
that hides `code` and a test that passes even if `code` were dropped.

**Cost.** A second public contract. Once a code ships, renaming it is a breaking change for the
frontend, so add one only where a client genuinely needs to branch on the reason. The audited
codebase ended up with 63 ad-hoc code strings and near-synonyms (`not_found` alongside
`user_not_found`, `customer_not_found`, `variant_not_found`) precisely because codes were authored
per call site. Ours can't drift the same way — every code is defined in one file — but the
vocabulary still needs to be kept small on purpose.

### 4. Business rules are app-level guards; the DB constraint is the backstop

**Decision.** Enforce a business rule with a check in the context that returns an error atom.
Keep the database constraint, but treat it as a corruption backstop rather than the user-facing
path.

**Why.** Two reasons compound here. The repo's existing rule is that anything a product decision
could change belongs in app code, not in a migration. On top of that, letting a constraint surface
the error costs you control of the message: a `unique_constraint` violation arrives as a changeset
error, which means a 422 naming whatever field you attached it to. The one-open-entry-per-task rule
originally reported `{"errors": {"task_id": ["has already been taken"]}}` — a column the client
never sent and cannot see. The app-level guard in `Brekitdown.TimeEntries` returns
`:entry_already_running` instead, and `:time_entries_one_open_per_task_index` stays in place to make
the invariant impossible to violate.

**Cost.** Check-then-insert is a race. Two simultaneous requests can both pass the guard, and the
constraint catches the loser — so that one request gets a 422 instead of a 409. Accepted
deliberately at single-user scale, and the reason the constraint's own message still needs to read
sensibly rather than being left at Ecto's default.

### 5. Lookups raise; operations return tuples

**Decision.** Fetch a resource named in the URL with the bang function (`get_task!/2`,
`get_time_entry!/3`) and let it raise. Return `{:ok, _}` / `{:error, _}` from anything that
creates, updates or deletes.

**Why.** This is what `phx.gen.json` generates, and it isn't arbitrary: `phoenix_ecto` already maps
`Ecto.NoResultsError` to 404 (see `deps/phoenix_ecto/lib/phoenix_ecto/plug.ex`, which also maps
`Ecto.CastError` and `Ecto.Query.CastError` to 400 and `Ecto.StaleEntryError` to 409). A missing
resource in a URL path is exceptional — no caller has a meaningful branch for it — so raising is
correct per Elixir's own guidance, and hand-rolling a 404 path duplicates machinery we already have.
It also gives cross-scope isolation for free: because the lookup is scoped, another user's
`reference_xid` raises the same `Ecto.NoResultsError` and 404s, revealing nothing. Tests assert this
with `assert_error_sent 404, fn -> … end`.

**Cost.** The 404 is invisible at the call site — nothing in `show/2` announces that it can 404, so
it's a convention you have to know. More importantly, it is only _correct_ while the bang function
includes the scope in its lookup. A bang lookup that forgets the scope doesn't produce a wrong
status; it produces a data leak.

### 6. Contexts return atoms, not formatted messages or statuses

**Decision.** `{:error, :entry_already_running}`. Never `{:error, "A time entry is already
running"}`, never `{:error, {409, "…"}}`.

**Why.** An atom is the only form that keeps the context testable without HTTP knowledge and lets
the web layer own presentation. Copy changes are then a one-line edit in the fallback, and the same
context function can be reused by a mix task or a background job that has no notion of a status
code. The audited codebase returned free-form strings from 169 call sites; the practical effect is
that user-facing copy is scattered through the domain layer and untestable as a contract.

**Cost.** A layer of indirection: reading the context alone doesn't tell you what the client sees.
That's the trade this document exists to offset.

## Response shapes

Three shapes. That's the whole surface.

```json
// 400, 401, 403, 404, 500
{"errors": {"detail": "Not Found"}}

// 409 — detail explains it on its own, code is the optional match key
{"errors": {"code": "entry_already_running", "detail": "This task already has a time entry that has not ended."}}

// 422 — field => messages
{"errors": {"ended_at": ["must not be before started_at"]}}
```

**422 has one shape regardless of which layer rejected the request.** `ValidationErrorPlug` exists
to make OpenApiSpex's cast failures look like `ChangesetJSON`'s output, so a client never has to
care whether the schema or the changeset said no. Two details worth knowing: the message vocabulary
differs between them (OpenApiSpex says `"Missing field: started_at"`, Ecto says `"can't be
blank"`), and a validation error with no field path is keyed `"body"`.

## Adding an error to the API

- [ ] Pick the status with the discriminator, not by what's easiest to return.
- [ ] Have the context return `{:error, :snake_case_atom}` — no status, no formatted message.
- [ ] Add the `call/2` clause to `FallbackController` **above** the catch-all, or it will never match.
- [ ] Write the real `detail` copy — what happened, and why. Append a remedy only if it restates a domain rule, never a workflow. No placeholders, no "TBD".
- [ ] For a 409: choose the `code`, and declare `conflict: {"…", "application/json", ConflictError}` in the action's `operation`.
- [ ] Declare every status the action can return in `operation`'s `responses:`.
- [ ] Assert the status **and** the `code` or field name — a test that only checks the status passes for the wrong reason.
- [ ] Pin the exact `detail` in `fallback_controller_test.exs`; keep controller tests on substrings so rewording touches one file.

## Sharp edges

- **`:unprocessable_content` and `unprocessable_entity` are both correct.** The first is the Plug
  status atom used in code (`put_status/2`, `send_resp/3`); the second is the OpenApiSpex
  `responses:` key. Both mean 422. Don't "fix" either one.

- **A 422 body names whatever you `cast`.** `ChangesetJSON` emits the changeset's own field names, so
  an internal column in a `cast` list or a `unique_constraint` target becomes part of your public
  error contract. This is exactly how the one-open-entry rule ended up reporting `task_id`. Check
  what a new changeset error is _called_ before shipping it.

- **401 bypasses `FallbackController`.** Changing the error envelope means changing `user_auth.ex`
  too. See "How an error travels".

- **`code` is on 409s only.** Don't write a client that expects it everywhere.

- **Timestamp formats: use `format: :"date-time"`, with the hyphen.** OpenApiSpex matches only that
  exact atom (`deps/open_api_spex/lib/open_api_spex/cast/string.ex:28`), where it casts via
  `DateTime.from_iso8601/1` — which requires an offset, and so rejects an offset-less
  `"2026-08-01T10:00:00"` that would otherwise be silently read as UTC and stored hours off. Older
  schemas use `format: :date_time` (underscore), which matches nothing: `due_at` is neither cast nor
  validated today. That's a real bug pending cleanup — don't copy it into new schemas.

## Sources

- Phoenix, `action_fallback/1` — <https://hexdocs.pm/phoenix/Phoenix.Controller.html#action_fallback/1>
- Phoenix, JSON and APIs guide — <https://hexdocs.pm/phoenix/json_and_apis.html>
- RFC 9110 §15.5.10, 409 Conflict — <https://www.rfc-editor.org/rfc/rfc9110.html#name-409-conflict>
- RFC 9110 §15.5.21, 422 Unprocessable Content — <https://www.rfc-editor.org/rfc/rfc9110.html#name-422-unprocessable-content>
- MDN, 409 — <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/409>
- MDN, 422 — <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/422>
- Ecto, `unique_constraint/3` (`:name`, `:message`, `:error_key`) — <https://hexdocs.pm/ecto/Ecto.Changeset.html#unique_constraint/3>
- Plug, `Plug.Exception` — <https://hexdocs.pm/plug/Plug.Exception.html>
- Elixir, design anti-patterns ("Exceptions for control-flow") — <https://hexdocs.pm/elixir/design-anti-patterns.html>

Cite the source when adding a "this is idiomatic" claim here, so a future session can re-check it
rather than take it on trust.

## Things to evaluate down the road

1. 404/401/500 bodies are the weakest part today, not tomorrow. "Not Found" with no hint of what wasn't found violates the doc's own self-sufficiency rule, and 404s are typically the majority of error traffic. A consumer hitting a nested route (/tasks/:id/time_entries/:id) can't tell which resource missed. This is the real consumer-experience gap; the 409 work polished the rarer case first.
2. The atom→clause link is unchecked. Fine at 4 atoms; at 40 atoms across 10 contexts, "new atom silently becomes a logged 500" will bite. You deferred the guard correctly, but this is the scaling cost with a known date.
3. FallbackController is a shared hotspot. Every feature touches one file. Solo, that's a feature (the whole point). On a team it becomes merge contention and a vocabulary-drift battleground — the single file prevents scattered codes but not near-synonym codes; that stays social discipline.
4. The race trade-off leaks into the contract. Under concurrency, the check-then-insert loser gets a 422 naming task_id instead of the 409 — the exact response shape the design exists to prevent. Accepted at single-user scale; a multi-client future would need Repo.transact with a lock or constraint-to-409 translation.
5. The envelope itself is Phoenix convention, not the HTTP standard. The industry answer to "error contract that scales across many consumers" is RFC 9457 Problem Details (application/problem+json, with type/title/detail/status). Your {"errors": {...}} shape is the generator idiom — fine and idiomatic for one first-party FE, but if this API ever went public/multi-consumer, that's the battle-tested format, and migrating an envelope is a breaking change across all four producers the doc lists.
