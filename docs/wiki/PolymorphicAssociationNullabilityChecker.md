# PolymorphicAssociationNullabilityChecker

`PolymorphicAssociationNullabilityChecker` finds polymorphic `belongs_to` associations whose foreign key and foreign type columns have different null constraints.

For an optional polymorphic association, both columns should allow `NULL`:

```ruby
create_table :pictures do |t|
  t.bigint :imageable_id, null: true
  t.string :imageable_type, null: true
end
```

For a required polymorphic association, both columns should be `NOT NULL`. A mismatch allows an incomplete polymorphic reference where only the id or type is present.
