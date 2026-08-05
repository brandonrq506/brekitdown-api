# Checklist for Tests

- [ ] Verify we are always using relative dates.
- [ ] Verify that you are using DateTime.shift/2 over add/3, as it offers a more ergonomic API.
- [ ] Never use Repo.insert!/2 or Repo.update!/2 in tests. 
- [ ] Auth user with helpers, not manually.
