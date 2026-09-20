# Task notes

- A note always belongs to exactly one task.
- Title and body are both required, and both are trimmed before they are stored.
- Title is at most 100 characters; body is at most 5000.
- Deleting a task deletes its notes.
- Notes are ordered newest first, `inserted_at` then `id` — timestamps truncate to the second,
  so two notes written in the same second need the id to break the tie.

## No `user_id` column

Ownership is transitive through `task_id`. Every entry point resolves the task through
`Tasks.get_task!(scope, …)` first, which is already scope-filtered, so a note can only be reached
by way of a task the caller owns. The context still asserts `task.user_id == scope.user.id`, so a
task fetched some other way fails loudly instead of leaking.

Cost: a cross-task notes feed ("everything I wrote this week") would need a join through `tasks`
rather than a `where user_id`.

## A task never carries its notes

`GET /api/tasks` and `GET /api/tasks/:id` both carry `notes_count` and neither carries the notes.
The notes come from `GET /api/tasks/:task_id/notes`, always — one way to fetch them, so a client
never has to work out which shape it was handed.

`notes_count` is a correlated subquery merged into the task `SELECT`, not a preload: Postgres
counts the rows without returning them. Adding `:notes` to a preload list is therefore never
needed to make the count work.

The reason it is a count and not the notes: `GET /api/tasks` has no pagination — it returns every
task the user owns — so inlining note bodies there multiplies two unbounded things.
