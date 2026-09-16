## Random learning

- You most likely want to define both a `get_entity!` and a `get_entity` function.
  - Use the raising one, when it's a direct call for that entity, and you want to ensure it exists or return a 404.
  - Use the second one, when you want to check if it exists, and handle the case where it doesn't exist gracefully, like a Goal for a Task.

- When preloading, there are two ways to do it, one is using `Repo.preload` and the other is using `preload` in the query.
  - Use `Repo.preload` when you have an existing struct and want to load associations for it.
  - Use `preload` in the query when you are querying for a struct and want to load associations in the same query.

- Being careful with blindly creating clauses. I was almost going to add `def get_goal(scope, nil), do: nil`.
  The problem with that is intention, what could in a valid way send nil to `get_goal`?
  The answer is: That's weird, and if that happens I want to know about it, so instead of silently returning nil, I want to raise an error.
  There IS a place where goal could be nil, which is when a Task is being created for a goal, however, there I have `maybe_put_goal` which handles that case gracefully.
  Meaning I only reach for `get_goal` when I know the goal reference_xid is not nil, and if it is, I want to know about it.
