See [https://github.com/djezzzl/database_consistency/issues/197](https://github.com/djezzzl/database_consistency/issues/197)

Avoid unpredictable behaviors when using non-sortable column as primary key, this is necessary when trying to prevent leaking internal ids.

`ImplicitOrderingChecker` perform check for the existence of `self.implicit_order_column` (or equivalent) method inside model file of table that satisfy the following conditions:

- using PostgreSQL adapter
- using primary key with `uuid` column type

Message:

```
ImplicitOrderingChecker fail <Model> <Column> implicit_order_column is recommended when using uuid column type for primary key
```
