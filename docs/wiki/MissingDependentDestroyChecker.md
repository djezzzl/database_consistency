This checker identifies cases where a `belongs_to` association is backed by a foreign key without an `on_delete` option. While the foreign key enforces data integrity by preventing orphaned records, attempting to delete the parent object will raise an error due to the database constraint.

To avoid such errors and handle deletions gracefully, you should either:

- Add a `dependent:` `:destroy`, `:delete`, `:delete_all`, or `:nullify` option to the corresponding `has_one` or `has_many` association.
- Set the foreign key's `on_delete` option to `cascade` or `nullify`.

Use case example:

```ruby
class User
  has_many :posts
end

class Post
  belongs_to :user
end

# schema.rb
add_foreign_key "posts", "users"
```
