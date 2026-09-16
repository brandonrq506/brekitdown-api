# DB records and associations lessons

## Snapshot vs. reference

There are things that change over-time and it's critical we store a copy of the original state of those things.
Example: Coupons to an order, a coupon may change, be percentage / fixed, but to ensure a historical record of what was applied, we need to store the original state of the coupon when the order was created.

Other things don't matter as much, like a goal's name, or a task's description, those can change over time and we don't need to store the original state of those things.

## Soft delete vs. hard delete

- Soft delete: Mark a record as deleted without actually removing it from the database. This allows for recovery and historical reference.

## Decide on_delete explicitly.

- It is important to explicitly decide the `on_delete` behavior for associations in your database schema. This ensures that you have a clear understanding of how deletions will propagate and helps prevent accidental data loss.

## Timestamp instead of boolean

- Instead of using a boolean field to indicate a state (e.g., `is_active`), consider using a timestamp field (e.g., `deactivated_at`). This provides more information about when the state changed and allows for easier historical tracking.

## Ownership is transitive; verify it

- When dealing with ownership in your database, remember that ownership is transitive. If a user owns a project, and a project owns a task, then the user indirectly owns the task.

Every query scopes through the chain. Scenario: Task belongs to Goal belongs to User. Creating a TimeEntry with a task_xid from someone else's task must fail. Your scope param exists for this; the lesson is "never join a child without joining up to the scope".

## Internal ID vs. public ID

- Use internal IDs (usually primary keys) for database relations and internal logic.
- Use public IDs (usually UUIDs or obfuscated IDs) for exposing resources externally, such as in APIs.
- This separation helps prevent leaking internal database structure and allows for safer refactoring of internal IDs without affecting external clients.

## Store units, not floats.

- When dealing with quantities that have a natural unit (e.g., cents for money, milliseconds for time), store the value as an integer representing the smallest unit instead of using a float. This avoids precision issues and makes calculations more reliable.

## State transitions, not free-form status

If a column has values like pending/verified/rejected, define allowed transitions in one place. Scenario: a Verification going rejected → verified should be impossible, not just unlikely.

## Ledgers are append-only

- When designing a ledger, never update or delete existing entries. Instead, append new entries to reflect changes. This ensures a complete and auditable history of all transactions.
