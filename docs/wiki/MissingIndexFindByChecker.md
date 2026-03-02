`MissingIndexFindByChecker` finds columns that are used in `find_by` calls (including dynamic finders) but are missing a database index, which can lead to slow queries.

The checker uses Ruby's built-in [Prism](https://github.com/ruby/prism) parser to scan project source files and detect the following patterns:

- `find_by_<column>(value)` — dynamic finder
- `find_by(column: value)` — symbol-key hash
- `find_by("column" => value)` — string-key hash

> **Note:** This checker requires Ruby 3.3+ (where Prism is part of the standard library). It is automatically skipped on older Ruby versions.

Use case example:

```ruby
class User < ApplicationRecord
end

User.find_by(email: "user@example.com")
```

If there is no index on the `email` column in the database, `database_consistency` will report it.

Message:

```
MissingIndexFindByChecker fail User email column is used in find_by but is missing an index (found at app/models/user.rb:42)
```
