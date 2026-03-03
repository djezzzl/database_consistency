The checker finds enums with value types different from the database's field.

The problem only becomes apparent when `prepared_statements:` option is set to `false`. This is typical and [recommended by Rails when connecting via PgBouncer](https://guides.rubyonrails.org/configuring.html#configuring-a-postgresql-database).

```
ActiveRecord::StatementInvalid: PG::UndefinedFunction: ERROR:  operator
   does not exist: text = integer
      LINE 1: SELECT "users".* FROM "users" WHERE "users"."os" = 0
```

```ruby
# app/models/user.rb
enum os: [:linux, :windows]

# db/schema.rb
t.text "os"
```

The data actually saved in the column is `'1'`, `'2'` etc.

With `prepared_statements: true` this error doesn't happen, and it works but it's preferable to keep it consistent to avoid implicit typecasting.
