# Changelog

### [1.1.10] - 2022/01/06

Improvements:
- Allow aliases in YAML config file for Ruby 3.1. Thanks [jlestavel](https://github.com/jlestavel) or the contribution!

### [1.1.9] - 2021/12/29 

- Fixed 1.1.8

### [1.1.8] - 2021/12/29 (yanked)

Improvements:
- Allow `ForeignKeyTypeChecker` to cover smaller types. Thanks [Artem Piankov](https://github.com/iBublik) for the contribution!

### [1.1.7] - 2021/12/08

Improvements:
- Add multiple files configuration support. Thanks [Artem Piankov](https://github.com/iBublik) for the contribution!

### [1.1.6] - 2021/11/10

Improvements:
- Output error message for ColumnPresenceChecker and ForeignKeyTypeChecker instead raising an error when field is missing.

### [1.1.5] - 2021/10/31

Improvements:
- Extend `NullConstraintChecker` to check required belongs_to associations with explanatory message.

### [1.1.4] - 2021/10/26

Improvements:
- Fix `BelongsToPresenceChecker` to to be independent from presence validation and rename it to `ForeignKeyChecker` to better reflect what it does.

### [1.1.3] - 2021/10/25

Improvements:
- Fix `ColumnPresenceChecker` to check association key columns. Thanks [Phil Pirozhkov](https://github.com/pirj) for the contribution!

### [1.1.2] - 2021/08/03

Improvements:
- Change the messages structure to always show checker name.

### [1.1.1] - 2021/04/25

Bugs:
- Check `where` clauses in comparison in `RedundantIndexChecker` and `RedundantUniqueIndexChecker`.

### [1.1.0] - 2021/04/24

Improvements:
- Implement `RedundantUniqueIndexChecker`.

### [1.0.0] - 2021/04/24

Improvements:
- Implement `RedundantIndexChecker`.

### [0.8.13] - 2021/01/04

Improvements:
- Ignore to ActiveStorage models on configuration template

### [0.8.12] - 2020/12/8

Improvements:
- Implement `UniqueIndexChecker`. Thanks [Pierre Berard](https://github.com/Berardpi) for the contribution!

### [0.8.11] - 2020/11/19

Bugs:
- Fix primary key for different associations for `ForeignKeyTypeChecker`.

### [0.8.10] - 2020/11/18

Bugs:
- Fix primary key for `ForeignKeyTypeChecker`.

### [0.8.9] - 2020/11/16

Bugs:
- Fix type casted fields comparison for `MissingUniqueIndexChecker`. Thanks [Artem Chubchenko](https://github.com/chubchenko) for reporting the issue.

### [0.8.8] - 2020/09/24

Bugs:
- Remove HABTM support from `ForeignKeyTypeChecker`
- Exclude HABTM classes for all checkers

### [0.8.7] - 2020/09/23

Bug:
- Fix support for custom foreign keys for `ForeignKeyTypeChecker`. Thanks [Thierry Deo](https://github.com/tdeo) for the contribution.

### [0.8.6] - 2020/09/22

Bug:
- Ignore `through` associations for `ForeignKeyTypeChecker`
- Fix column finder for `ForeignKeyTypeChecker`

### [0.8.5] - 2020/09/21

Improvements:
- Introduce `ForeignKeyTypeChecker`.

### [0.8.4] - 2020/07/04

Improvements:
- `LengthConstraintChecker` now ignores array columns (PostgreSQL only)

### [0.8.3] - 2020/06/24

Improvements:
- Consider `on` option for `PresenceValidator` as weak for `ColumnPresenceChecker`
- Support relations for `scope` for `MissingUniqueIndexChecker`

### [0.8.2] - 2020/06/20

Improvements:
- Add consideration of numericality validator to `NullConstraintChecker`. Thanks [Bob Maerten](https://github.com/bobmaerten) for adding this.

### [0.8.1] - 2020/06/03

Improvements:
- Introduce `bundle exec database_consistency install`. Thanks [goulvench](https://github.com/goulvench) for implementing this.

### [0.8.0] - 2020/03/02

Improvements:
- Introduce `PrimaryKeyTypeChecker`.

### [0.7.9] - 2020/02/20

Improvements:
- `NullConstraintChecker` now considers `ExclusionValidator` with `nil`.

### [0.7.8] - 2020/02/02

Bug:
- Fix `BelongsToPresenceChecker` to consider only `belongs_to` associations.

### [0.7.7] - 2020/01/29

Bug:
- Fix configuration check.

### [0.7.5] - 2019/10/12

Bug:
- Fix eager loading for Zeitwerk.

### [0.7.6] - 2019/12/16

Fix:
- Make `ColumnPresenceChecker` to consider group of validators instead one by one.
That decreases amount of false negative scenarios.

### [0.7.4] - 2019/08/18

Improvements:
- Add support of Rails 6

### [0.7.3] - 2019/07/24

Fix:
- Custom validators won't raise an error

### [0.7.2] - 2019/07/05

Fix:
- `bundle exec database_consistency` exits with fail if there was any error
- Skip `MissingIndexChecker` when associated model doesn't exist

### [0.7.1] - 2019/06/22

Fix:
- Ignore non-string columns for `LengthConstraintChecker`

### [0.7.0] - 2019/06/16

Improvements:
- Add support of `LengthConstraintChecker`

### [0.6.9] - 2019/05/19

Fixes:
- Return error code if output contains any failing message

### [0.6.8] - 2019/05/05

Improvements:
- Add support of compound indexes to `MissingIndexChecker`
- Add colored output
- Removed welcome message from execution

### [0.6.7] - 2019/05/01

Fixes:
- Fix disabling models from checks

### [0.6.6] - 2019/04/18

Improvements:
- Add support `case_sensitive: false` for `MissingUniqueIndexChecker`

### [0.6.5] - 2019/01/30

Improvements:
- Exclude superclasses associations from `MissingIndexChecker`

### [0.6.4] - 2019/01/27

Improvements:
- Change documentation
- Refactor code

### [0.6.3] - 2019/01/27

Improvements:
- Add message to inspire people to collaborate
- Add `RescueError` to catch possible error

### [0.6.2] - 2019/01/26

Improvements:
- Skip `NullConstraintChecker` is column has default function
- Improve specs to test different databases

### [0.6.1] - 2019/01/22

Fixes:
- Fix empty configuration file support
- Fix `MissingIndexChecker`, we don't support `through` associations for now

Improves:
- Extend configuration to support complete turning off particular checker

### [0.6.0]

Features:
- Introduce `MissingIndexChecker` to find missing indexes for `HasOne` and `HasMany` associated models.

Improvements:
- Change message templates to be more informative

### [0.5.0] - 2019/01/11

Features:
- Introduce `MissingUniqueIndexChecker` to find missing unique indexes.

Breaking changes:
- Change schema of the configuration file. Please update to the new version according to the [example](example/.database_consistency.yml).

### [0.4.0] - 2019/01/10

Features:
- Introduce `BelongsToPresenceChecker` to find missing foreign keys.

Breaking changes:
- Rename `PresenceValidationChecker` to `ColumnPresenceChecker` for simplicity. Please update your configuration files properly.

### [0.3.0] - 2019/01/04

Features:
- Support flexible configuration (disable specified check for specified column)

Breaking changes:
- Configuration should be provided according to the new format

### [0.2.5] - 2018/11/24

Improvements:
- Exclude subclasses from ValidatorsProcessor

### [0.2.4] - 2018/11/15

Features:
- Support of [overcommit](https://github.com/brigade/overcommit) gem

### [0.2.3] - 2018/11/14

Improvements:
- Exclude columns with default value from PresenceMissingVerifier

Features:
- Support configurations via yml file

### [0.2.2] - 2018/11/12

Improvements:

- Exclude Inclusion validator and BelongsTo association from being alerted by PresenceMissingVerifier

### [0.2.1] - 2018/10/31

Improvements:

- Add support of ActiveRecord 4.2+ ([link](https://github.com/djezzzl/database_consistency/pull/2)).

### [0.2.0] - 2018/10/31

Features:

- Add check of missing presence validator

### [0.1.0] - 2018/10/30

Features:

- Add check of consistency between presence validator and database field
