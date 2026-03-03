Sometimes, your associations point to an undefined model. That could be fine if you don't use those associations anymore. However, it's always good to clean them up for the codebase or to fix them by specifying a `class_name` or generating a model.

Example:

```ruby
class User < ApplicationRecord
  has_many :something
end
```

If no `Something` model exists in your codebase, `database_consistency` will find it.

P.S. The check is not supported by `polymorphic` associations.
