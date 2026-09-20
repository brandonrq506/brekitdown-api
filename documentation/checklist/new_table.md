# Checklist for Adding a New Table

- [ ] Add a new migration with `mix ecto.gen.migration table_name_using_underscores`.
- [ ] Update the migration to define all the fields, the `reference_xid` column, and the proper nullability constraints.
- [ ] Update the schema module accordingly.
- [ ] Update associations in the schema module accordingly.
