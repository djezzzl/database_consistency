Imagine your model has `validates :age, numericality: { greater_than_or_equal_to: 0 }` validation but does not have a `CHECK` constraint for the field in the database. In that case, invalid values can still be inserted outside your model validations. This checker helps ensure numericality validations are backed by a database `CHECK` constraint.

`numericality` validators without a range option (e.g. bare `numericality: true`) are skipped, since no CHECK constraint can express them.
