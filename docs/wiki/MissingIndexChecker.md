Imagine your model has a `has_one :user` association but has no index in the database. In this case, querying the database to get the associated instance can be very inefficient. Mostly, you'll need an index to process such queries fast.

Additionally, `has_one` associations should be unique on the database level to avoid unexpected behavior.
