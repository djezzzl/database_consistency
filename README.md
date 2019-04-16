# DatabaseConsistency

[![Build Status](https://travis-ci.org/djezzzl/database_consistency.svg?branch=master)](https://travis-ci.org/djezzzl/database_consistency)
[![Gem Version](https://badge.fury.io/rb/database_consistency.svg)](https://badge.fury.io/rb/database_consistency)

The main goal of the project is to provide an easy way to check the consistency of the 
database constraints with the application validations.

Currently, we can:
- find missing null constraints ([ColumnPresenceChecker](#columnpresencechecker))
- find missing presence validations ([NullConstraintChecker](#nullconstraintchecker))
- find missing foreign keys for `BelongsTo` associations ([BelongsToPresenceChecker](#belongstopresencechecker))
- find missing unique indexes for uniqueness validation ([MissingUniqueIndexChecker](#missinguniqueindexchecker))
- find missing index for `HasOne` and `HasMany` associations ([MissingIndexChecker](#missingindexchecker))

We also provide flexible configuration ([example](rails-example/.database_consistency.yml)) and [integrations](#integrations)

We support the following databases: `SQLite3`, `PostgreSQL` and `MySQL`.
We support any framework or pure ruby which uses ActiveRecord. 

Check out the [database_validations](https://github.com/toptal/database_validations) to have faster and reliable
uniqueness validations and `BelongsTo` associations using ActiveRecord.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'database_consistency', group: :development, require: false
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install database_consistency
```

## Usage

In the root directory of your Rails project run `bundle exec database_consistency`. 
To get a full output run `LOG_LEVEL=DEBUG bundle exec database_consistency`.

For any other framework or pure ruby, you can copy the following code and create a file `database_consistency_runner.rb`.

```ruby
# First of all, you need to load all models
# The following example is for Rails, but it can be anything  
require_relative 'config/environment'
Rails.application.eager_load!

# Now start the check
require 'database_consistency'
result = DatabaseConsistency.run
exit result
```

Now, just start the script: `bundle exec ruby database_consistency_runner`.

You can also configure the gem to skip some of its checks using [.database_consistency.yml](rails-example/.database_consistency.yml) file.
By default, every checker is enabled. 

## How it works?

### ColumnPresenceChecker

Imagine your model has a `validates :email, presence: true` validation on some field but doesn't have not-null constraint in 
the database. In that case, your model's definition assumes (in most cases) you won't have `null` values in the database but 
it's possible to skip validations or directly write improper data in the table. 

To avoid the inconsistency and be always sure your value won't be `null` you should add not-null constraint.

| allow_nil/allow_blank/if/unless | database | status |
| :-----------------------------: | :------: | :----: |
| at least one provided           | required | fail   |
| at least one provided           | optional | ok     |
| all missing                     | required | ok     |
| all missing                     | optional | fail   |  

### NullConstraintChecker

Imagine your model has not-null constraint on some field in the database but doesn't have 
`validates :email, presence: true` validation. In that case, you're sure that you won't have `null` values in the database.
But each attempt to save the `nil` value on that field will be rolled back with error raised and without `errors` on your object.
Mostly, you'd like to catch it properly and for that presence validator exists.

We fail if the column satisfies the following conditions:
- column is required in the database
- column is not a primary key (we don't need need presence validators for primary keys)
- model records timestamps and column's name is not `created_at` or `updated_at`
- column is not used for any Presence or Inclusion validators or BelongsTo association
- column has not a default value
- column has not a default function

### BelongsToPresenceChecker

Imagine your model has a `validates :user, presence: true` or `belongs_to :user, optional: false` 
(since Rails 5+ optional is `false` by default). In both cases, you assume your instance has a persisted relation with another
model which can be not true. For example, we can skip validations or remove connected instance after insert and etc. So, 
to keep your data consistency, in most cases, you should define a foreign key constraint in the database. It will ensure your
relation exists. 

We fail if the following conditions are satisfied:
- belongs_to association is not polymorphic
- belongs_to association has presence validator
- there is no foreign key constraint

### MissingUniqueIndexChecker

Imagine your model has a `validates :email, uniqueness: true` validation but has no unique index in the database. As general
problem your validation can be skipped or there is possible duplicates insert because of race condition. To keep your data 
consistent you should cover your validation with proper unique index in the database (if possible). It will ensure you don't
have duplicates.

We fail if the following conditions are satisfied:
- there is no unique index for the uniqueness validation 

### MissingIndexChecker

Imagine your model has a `has_one :user` association but has no index in the database. In this case querying the database
to get the associated instance can be very inefficient. Mostly, you'll need an index to process such queries fast. 

We fail if the following conditions are satisfied:
- there is no index for the `HasOne` or `HasMany` association
- it has a `through` option

## Example

```
$ bundle exec database_consistency
fail User code column is required in the database but do not have presence validator
fail User phone column should be required in the database
fail User name column is required but there is possible null value insert
fail User name+email model should have proper unique index in the database
fail User company model should have proper foreign key in the database
fail Company user associated model should have proper index in the database
fail Country users associated model should have proper index in the database
```

See [rails-example](rails-example) project for more details.

## Integrations

Configuration example for [overcommit](https://github.com/brigade/overcommit) gem. 

```yaml
PreCommit:
  DatabaseConsistency:
    enabled: true
    quiet: false
    command: ['bundle', 'exec', 'database_consistency']
```

## Development

After checking out the repo, run `bundle install` to install dependencies. 
You need to have installed and running `postgresql` and `mysql`. 
And for each adapter manually create a database called `database_consistency_test` accessible by your local user.

#### MySQL

```
# user is your local user from $whoami command
mysql -uroot --password
mysql> CREATE DATABASE database_consistency_test;
mysql> CREATE USER user@localhost IDENTIFIED BY '';
mysql> GRANT ALL PRIVILEGES ON database_consistency_test.* TO user@localhost;
```

#### PostgreSQL

```
psql postgres
postgres=# CREATE DATABASE database_consistency_test;
```

Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, 
update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git 
tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

[Bug reports](https://github.com/djezzzl/database_consistency/issues) and [pull requests](https://github.com/djezzzl/database_consistency/pulls) are welcome on GitHub. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected 
to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the *DatabaseConsistency* project’s codebases, issue trackers, chat rooms 
and mailing lists is expected to 
follow the [code of conduct](CODE_OF_CONDUCT.md).

## Changelog

*DatabaseConsistency*'s changelog is available [here](CHANGELOG.md).

## Copyright

Copyright (c) Evgeniy Demin. See [LICENSE.txt](LICENSE.txt) for further details.
