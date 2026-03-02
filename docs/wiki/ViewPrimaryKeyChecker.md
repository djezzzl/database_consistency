`ViewPrimaryKeyChecker` finds models that point to a database view but do not have `primary_key` properly set.

When a model is backed by a view rather than a regular table, ActiveRecord cannot automatically determine the primary key. Without a `primary_key` set, operations like record lookup, associations, and caching may not work correctly.

The checker reports a failure in two cases:

| Condition | Status |
| --------- | ------ |
| `primary_key` is blank (not set) | fail |
| `primary_key` is set but the column does not exist in the view | fail |
| `primary_key` is set and the column exists | ok |

Use case example:

```ruby
# Bad: model points to a view without primary_key set
class ReportView < ApplicationRecord
  self.table_name = "report_view"
end

# Good: primary_key is explicitly set
class ReportView < ApplicationRecord
  self.table_name = "report_view"
  self.primary_key = "id"
end
```

Messages:

```
ViewPrimaryKeyChecker fail ReportView self model pointing to a view should have primary_key set
ViewPrimaryKeyChecker fail ReportView self model pointing to a view has a non-existent primary_key column set
```
