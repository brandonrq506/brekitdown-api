# Time entries

- A task with subtasks cannot receive time entries.
- A task can have at most one open time entry (`ended_at` is null).
- A time entry's `ended_at` can never precede its `started_at`; the same second is fine.
