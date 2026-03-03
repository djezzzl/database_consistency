Boolean columns without a `NOT NULL` constraint can hold three states: `true`, `false`, and `NULL`. This is rarely intentional and can lead to unexpected behavior in your application logic, since `NULL` is neither `true` nor `false`.

`ThreeStateBooleanChecker` finds boolean columns that are missing a `NOT NULL` constraint in the database.

To fix the issue, add a `NOT NULL` constraint and set a default value for the column:

```ruby
# In a migration:
change_column_null :table_name, :column_name, false
change_column_default :table_name, :column_name, false
```
