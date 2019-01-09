# DatabaseConsistency

[![Build Status](https://travis-ci.org/djezzzl/database_consistency.svg?branch=master)](https://travis-ci.org/djezzzl/database_consistency)
[![Gem Version](https://badge.fury.io/rb/database_consistency.svg)](https://badge.fury.io/rb/database_consistency)

The main goal of the project is to provide an easy way to check the consistency of the 
database constraints with the application validations.

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

You can also configure the gem to skip some of its checks using [.database_consistency.yml](example/.database_consistency.yml) file.
By default, every checker is enabled. 

## How it works?

### PresenceValidationChecker

Imagine your model has a `validates <field>, presence: true` validation on some field but doesn't have not-null constraint in 
the database. In that case, your model's definition assumes (in most cases) you won't have `null` values in the database but 
it's possible to skip validations or directly write improper data in the table. 

To avoid the inconsistency and be always sure your value won't be `null` you should add not-null constraint.

| allow_nil/allow_blank/if/unless | database | status |
| :-----------------------------: | :------: | :----: |
| at least one provided           | required | fail   |
| at least one provided           | optional | ok     |
| all missed                      | required | ok     |
| all missed                      | optional | fail   |  

### NullConstraintChecker

Imagine your model has not-null constraint on some field in the database but doesn't have 
`validates <field>, presence: true` validation. In that case, you're sure that you won't have `null` values in the database.
But each attempt to save the `nil` value on that field will be rolled back with error raised and without `errors` on your object.
Mostly, you'd like to catch it properly and for that presence validator exists.

We fail if the column satisfies the following conditions:
- column is required in the database
- column is not a primary key (we don't need need presence validators for primary keys)
- model records timestamps and column's name is not `created_at` or `updated_at`
- column is not used for any Presence or Inclusion validators or BelongsTo reflection
- column has not a default value

## Example

```
$ bundle exec database_consistency
fail User phone should be required in the database
fail User name is required but possible null value insert
fail User code is required but do not have presence validator
```

See [example](example) project for more details.

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

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

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
