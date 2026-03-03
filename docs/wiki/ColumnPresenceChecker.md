Imagine your model has a `validates :email, presence: true` validation on some field or a required `belongs_to :user` association but doesn't have a not-null constraint in the database. In that case, your model's definition assumes (in most cases) you won't have `null` values in the database but it's possible to skip validations or directly write improper data in the table.

Keep in mind that `belongs_to` is required by default starting from Rails 5 given `config.load_defaults` is in place and unless `config.active_record.belongs_to_required_by_default` is explicitly set to `false`.

To avoid the inconsistency and be always sure your value won't be `null` you should add not-null constraint.
