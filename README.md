# DatabaseConsistency

[![](https://badge.fury.io/rb/database_consistency.svg)](https://badge.fury.io/rb/database_consistency)
[![](https://github.com/djezzzl/database_consistency/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/djezzzl/database_consistency/actions/workflows/tests.yml?query=event%3Aschedule)
[![](https://github.com/djezzzl/database_consistency/actions/workflows/rubocop.yml/badge.svg?branch=master)](https://github.com/djezzzl/database_consistency/actions/workflows/rubocop.yml?query=event%3Aschedule)
[![](https://opencollective.com/database_consistency/tiers/badge.svg)](https://opencollective.com/database_consistency#support)

The main goal of the project is to help you avoid various issues due to inconsistencies and inefficiencies between a database schema and application models.

> If the project helps you or your organization, I would be very grateful if you [contribute](https://github.com/djezzzl/database_consistency#contributing) or [donate](https://opencollective.com/database_consistency#support).  
> Your support is an incredible motivation and the biggest reward for my hard work.

For detailed information, please read the [wiki](https://github.com/djezzzl/database_consistency/wiki).

Currently, the tool can:
- find missing null constraints
- find missing length validations
- find missing presence validations
- find missing uniqueness validations
- find missing foreign keys for `BelongsTo` associations
- find missing unique indexes for uniqueness validation
- find missing indexes for `HasOne` and `HasMany` associations
- find primary keys with integer/serial type
- find mismatching primary key types with their foreign keys
- find redundant non-unique indexes
- find redundant uniqueness constraints
- find mismatching enum types with their values
- find mismatching foreign key cascades
- find inconsistent values between enums in the database and ActiveRecord's enums/inclusion validations

Besides that, the tool provides:
- auto-correction
- flexible configuration
- slow start with TODO files

We support the following databases: `SQLite3`, `PostgreSQL` and `MySQL`.  
We support [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) only at the moment.
Please upvote the request for other frameworks if you're interested.

## Usage

Add this line to your application's Gemfile:

```ruby
gem 'database_consistency', group: :development, require: false
```

And then execute:

```bash
$ bundle install
```

### Example

```bash
$ bundle exec database_consistency
NullConstraintChecker fail User code column is required in the database but do not have presence validator
NullConstraintChecker fail User company_id column is required in the database but do not have presence validator for association (company)
LengthConstraintChecker fail Company note column has limit in the database but do not have length validator
MissingUniqueIndexChecker fail User name+email model should have proper unique index in the database
ForeignKeyChecker fail User company should have foreign key in the database
ForeignKeyTypeChecker fail User company associated model key (id) with type (integer) mismatches key (company_id) with type (integer(8))
MissingIndexChecker fail Company user associated model should have proper index in the database
ForeignKeyTypeChecker fail Company user associated model key (company_id) with type (integer(8)) mismatches key (id) with type (integer)
MissingIndexChecker fail Country users associated model should have proper index in the database
ColumnPresenceChecker fail User phone column should be required in the database
ColumnPresenceChecker fail User name column is required but there is possible null value insert
UniqueIndexChecker fail User index_users_on_name_and_slug index is unique in the database but do not have uniqueness validator
RedundantUniqueIndexChecker fail User index_users_on_name_and_slug index uniqueness is redundant as (index_users_on_slug) covers it
RedundantIndexChecker fail User index_users_on_phone index is redundant as (index_users_on_phone_and_slug) covers it
ColumnPresenceChecker fail User tmp column (tmp) is missing in table (users) but used for presence validation
ForeignKeyTypeChecker fail User something association (something) of class (User) relies on field (something_id) of table (users) but it is missing
```

## Funding

### Open Collective Backers

You're an individual who wants to support the project with a monthly donation. Your logo will be available on the Github page. [[Become a backer](https://opencollective.com/database_consistency#backer)]

<a href="https://opencollective.com/database_consistency/backer/0/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/0/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/1/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/1/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/2/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/2/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/3/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/3/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/4/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/4/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/5/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/5/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/6/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/6/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/7/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/7/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/8/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/8/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/9/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/9/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/10/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/10/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/11/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/11/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/12/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/12/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/13/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/13/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/14/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/14/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/15/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/15/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/16/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/16/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/17/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/17/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/18/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/18/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/19/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/19/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/20/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/20/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/21/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/21/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/22/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/22/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/23/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/23/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/24/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/24/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/25/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/25/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/26/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/26/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/27/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/27/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/28/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/28/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/backer/29/website" target="_blank"><img src="https://opencollective.com/database_consistency/backer/29/avatar.svg"></a>

### Open Collective Sponsors

You're an organization that wants to support the project with a monthly donation. Your logo will be available on the Github page. [[Become a sponsor](https://opencollective.com/database_consistency#sponsor)]

<a href="https://opencollective.com/database_consistency/sponsor/0/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/1/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/2/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/3/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/4/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/5/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/6/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/7/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/8/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/9/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/9/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/10/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/10/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/11/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/11/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/12/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/12/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/13/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/13/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/14/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/14/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/15/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/15/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/16/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/16/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/17/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/17/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/18/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/18/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/19/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/19/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/20/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/20/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/21/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/21/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/22/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/22/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/23/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/23/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/24/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/24/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/25/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/25/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/26/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/26/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/27/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/27/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/28/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/28/avatar.svg"></a>
<a href="https://opencollective.com/database_consistency/sponsor/29/website" target="_blank"><img src="https://opencollective.com/database_consistency/sponsor/29/avatar.svg"></a>

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
