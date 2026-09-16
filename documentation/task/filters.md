# Task filtering

GET `/api/tasks` accepts indexed Flop filters, combined with AND. It remains in the
authenticated `/api` scope (`:api`, `:require_authenticated_user`) and always scopes
results to the current user. Responses remain `{data: [...]}` without pagination.

| Field | Operators | Operand |
| --- | --- | --- |
| goal_reference_xid | == | UUID string |
| due_at | ==, !=, <, <=, >, >= | ISO timestamp with offset or Z |
| due_at | in, not_in | Nonempty list of timestamps |
| due_at | empty, not_empty | Boolean |

Use `filters[0][field]=due_at&filters[0][op]=empty&filters[0][value]=false`
to request tasks with a due date. Membership operands use repeated
`filters[0][value][]=...` keys, never indexed `value[0]` keys.

Comparisons use timestamp instants. Offsets normalize to UTC and fractional seconds
follow the existing `:utc_datetime` second precision. Comparisons, including `!=`
and `not_in`, do not include null due dates; use emptiness operators explicitly.

Unsupported fields/operators, missing values, invalid dates, invalid operand shapes,
and extra properties return 422 with `{errors: {key: [messages]}}`. The four-branch
OpenAPI `oneOf` validator can produce multiple messages per field and a composite
filter-index error. Clients must not assume one message per field.

Sorting, pagination, tags, and other timestamp fields are not supported. The frontend
property/operator map supports one occurrence per field/operator; no OR groups.

`test/fixtures/task-filter-wire.json` contains actual output from the frontend
`src/utils/api-filters.ts` serializer for membership, false booleans, and offsets.
Controller tests consume those encoded strings through Plug, OpenApiSpex, and Flop.
Regenerate these fixtures from that serializer when changing wire encoding and run
both frontend serializer tests and backend controller tests.
