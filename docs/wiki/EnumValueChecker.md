The checker ensures that the database enum values and ActiveRecord's enum values/inclusion validations are aligned.

For example, let's assume we have the following `User` model.

```ruby
class User < ActiveRecord::Base
  enum :status, { value: 'value', unknown_value: 'unknown_value' }
  # or
  validates :status, inclusion: { in: %w[value unknown_value] }
end
```

and the database schema:

```ruby
create_enum :status_type, %w[value value2]

create_table :users do |t|
  # ...
  t.enum :status, enum_type: :status_type
  # ...
end
```

Then, the library will catch that there is an inconsistent value.

_Note:_ Currently, only `PostgreSQL` is supported.
