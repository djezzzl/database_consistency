Imagine your model has a limit constraint on some field in the database but doesn't have `validates :email, length: { maximum: <VALUE> }` validation. In that case, you're sure that you won't have values with exceeded length in the database. But each attempt to save a value with exceeded length on that field will be rolled back with an error raised and without errors on your object.

Mostly, you'd like to catch it properly and for that length-validator exists.
