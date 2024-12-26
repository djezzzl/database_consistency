# Changelog

### [2.0.1] - 2024/12/26

- Fix `ThreeStateBooleanChecker`, `ColumnPresenceChecker` and `ForeignKeyChecker` by ignoring views. Thanks [Wenley Tong](https://github.com/wenley) for reporting this!

### [2.0.0] - 2024/12/25

- Add support of custom checker classes. Thanks [Sergey Toy](https://github.com/toydestroyer) for the suggestion and implementation!

### [1.7.27] - 2024/12/24

- Fix generating migrations for newer versions of Rails. Thanks [André Arko](https://github.com/indirect) for reporting the issue. 

### [1.7.26] - 2024/10/09

- Improve generating migrations by using migration pool from connection. Thanks [Stephen Ierodiaconou](https://github.com/stevegeek) for noticing and fixing this!

### [1.7.25] - 2024/08/24

- Fix compatibility w/ active_type gem and handling anonymous classes. Thanks [ojab](https://github.com/ojab) for fixing this!
- Improving CI. Thanks [ojab](https://github.com/ojab) for doing this!
- Make all models methods ignore database disabled models. Thanks [Chedli Bourguiba](https://github.com/chaadow) for fixing it!

### [1.7.24] - 2024/08/22

- Fix DatabaseConsistencyCheckers/All setting
- Make LengthConstraintChecker ignore Proc/Symbol settings
- Handle lower() index in autofix migration writer

Thanks [Alexander Sviridov](https://github.com/ql) for fixing all of this!

### [1.7.23] - 2023/12/18

- EnumValueChecker: Check enums in any order. Thanks [Sergey Toy](https://github.com/toydestroyer) for noticing and improving this!

### [1.7.22] - 2023/11/08

- Adjust error file. Thanks [Andy Allan](https://github.com/gravitystorm) for reporting this!

### [1.7.21] - 2023/10/15

- Adjust `ColumnPresenceChecker` to work with ActiveRecord 7.1. Thanks [Alex Robbin](https://github.com/agrobbin) to create an issue and [Chedli Bourguiba](https://github.com/chaadow) for fixing it.

### [1.7.20] - 2023/08/22

- Ignore models without connected tables. Thanks [Francesco](https://github.com/frodsan) for the contribution!

### [1.7.19] - 2023/08/17

- Ignore disconnected models.

### [1.7.18] - 2023/07/22

- Implement `ImplicitOrderingChecker`. Thanks [Nhan Nim](https://github.com/developie0610) for the contribution!

### [1.7.17] - 2023/07/16

- Improve `MissingAssociationClassChecker` to work with invalid `through` associations.

### [1.7.16] - 2023/07/16

- Output debugging context for found issues.

### [1.7.15] - 2023/07/13

- Implement `MissingTableChecker` when find a model that is missing its table so it can be either removed completely or fixed.

### [1.7.14] - 2023/07/13

- Fix `ForeignKeyTypeChecker` when associated class has no table. Thanks [Andrius Chamentauskas](https://github.com/andriusch) for fixing the bug!

### [1.7.13] - 2023/07/09

- Add a new checker `MissingAssociationClassChecker` which finds associations that point to undefined models. Thanks [Manuel L.](https://github.com/PuntoDiGoccia) for suggesting the feature!
- Fix `ForeignKeyTypeChecker` according to `MissingAssociationClassChecker`. 

### [1.7.12] - 2023/07/05

- Add support of disabling checks per database connection. Thanks [epidevops](https://github.com/epidevops) for suggesting the feature!

### [1.7.11] - 2023/07/01

- Add support of regexp for configuration. Thanks [Klaus Weidinger](https://github.com/mak-dunkelziffer) for suggesting the feature!

### [1.7.10] - 2023/06/24

- Fixes `MissingIndexChecker` to consider compound indexes. Thanks [Ivan Atanasov](https://github.com/iatanas0v) for reporting the issue!

### [1.7.9] - 2023/06/22

- Stops modifying `ActiveRecord::Base.descendants`. Thanks [Thierry Deo](https://github.com/tdeo) for fixing the bug!

### [1.7.8] - 2023/05/01

- Add stable order when generate TODO file. Thanks [Olly Chadwick](https://github.com/greytape) for reporting this!

### [1.7.7] - 2023/05/01

- Improved specs. Thanks [Sergey Toy](https://github.com/toydestroyer) for taking care of this!
- Fix undefined method error in ColumnPresenceChecker. Thanks [Alan Savage](https://github.com/asavageiv) for the contribution!

### [1.7.6] - 2023/04/16

- Fix `ForeignKeyCascadeChecker` by treating `nil` as `restrict`. Thanks [Arkadiy Zabazhanov](https://github.com/pyromaniac) for fixing this!
- Add `ThreeStateBooleanChecker`. Thanks [Sergey Toy](https://github.com/toydestroyer) for implementing this!

### [1.7.5] - 2023/03/05

- Support multiple root-level models for the same table. Thanks [Bartek Bułat](https://github.com/barthez) for improving this!

### [1.7.4] - 2023/01/20

- Fix removed `File.exists?`. Thanks [Dennis Paagman](https://github.com/djfpaagman) for fixing the issue!

### [1.7.3] - 2023/01/12

- Improve messaging for `NullConstraintChecker`. Thanks [hanzongyu](https://github.com/hanzongyu) for spotting the issue!
- Avoid populating duplicated migrations. Thanks [zapxcero](https://github.com/zapxcero) for catching the issue!

### [1.7.2] - 2023/01/02

- Avoid unnecessary deprecations warnings.

### [1.7.1] - 2022/12/21

- Fix `EnumValueChecker` as `enums` are supported by Ruby on Rails 7+. Thanks [Sergey Toy](https://github.com/toydestroyer) for catching and fixing the issue!

### [1.7.0] - 2022/12/05

Implement `CaseSensitiveUniqueValidationChecker` that ensures case insensitive type doesn't have `case_sensitive: false` option on unique validations.

### [1.6.0] - 2022/12/03

- Implement `EnumValueChecker` that ensures consistency between PostgreSQL enum type and ActiveRecord's enum and inclusion validation. Thanks [Michal Papis](https://github.com/mpapis) for suggesting this!

### [1.5.3] - 2022/12/01

- Fix `ColumnPresenceChecker` autofix for polymorphic `belongs_to` associations. Thanks [Sergey Toy](https://github.com/toydestroyer) for catching the issue!

### [1.5.2] - 2022/11/30

- Fix `-help` option to output correct options. Thanks [la-magra](https://github.com/la-magra) for catching the issue!

### [1.5.1] - 2022/11/29

- Fix `EnumTypeChecker` to consider PostgreSQL enum types. Thanks [Sergey Toy](https://github.com/toydestroyer) for catching the issue!

### [1.5.0] - 2022/11/28

- Implement `ForeignKeyCascadeChecker`. Thanks [Phil Pirozhkov](https://github.com/pirj) for the suggestion!

### [1.4.1] - 2022/11/27

- Reduce warnings when `$VERBOSE=true`. Thanks [John Yeates](https://github.com/unikitty37) for the suggestion!
- Avoid missing columns errors for `ColumnPresenceChecker` and `EnumTypeChecker`. Thanks [John Yeates](https://github.com/unikitty37) for the suggestion!

### [1.4.0] - 2022/11/27

- Implement `EnumTypeChecker`. Thanks [Phil Pirozhkov](https://github.com/pirj) for the suggestion! 

### [1.3.9] - 2022/11/26

- Output loaded configurations for clarity.

### [1.3.8] - 2022/11/23

- Add fund metadata

### [1.3.7] - 2022/11/22

Improvements:
- Group similar issues on Simple::Writer.

### [1.3.6] - 2022/11/19

Improvements:
- Improve Simple::Writer to avoid duplicates. Thanks [Phil Pirozhkov](https://github.com/pirj) for the suggestion!

### [1.3.5] - 2022/11/13

Improvements:
- Add autofix for `ForeignKeyTypeChecker`.
- Add autofix for `MissingIndexChecker`.
- Add autofix for `MissingUniqueIndexChecker`

### [1.3.4] - 2022/11/12

Improvements:
- Provide autofix for `RedundantUniqueIndexChecker`.

Fixes:
- Fix unique sorting for autofix.

### [1.3.3] - 2022/11/12

Improvements:
- Provide autofix for `RedundantIndexChecker`. 

### [1.3.2] - 2022/11/11

Fixes:
- Fix `UniqueIndexChecker` to properly work with associations. Thanks [Christos Zisopoulos](https://github.com/christos) for catching the issue!

### [1.3.1] - 2022/11/07

Fixes:
- Fixed non-unique name for ForeignKeyChecker autofix. Thanks [Sergey Toy](https://github.com/toydestroyer) for catching the issue!

### [1.3.0] - 2022/11/06

Improvements:
- Introduce autofix option for several checkers.

### [1.2.2] - 2022/09/10

Improvements:
- Catch errors on processors so they don't break the whole run.

Fixes:
- Fix `IndexProcessor` to support multiple databases.

### [1.2.1] - 2022/09/05

Improvements:
- Add TODO generation.

### [1.2.0] - 2022/09/05

Improvements:
- Add global configuration support. Now it's possible to disable everything in one line and enable some on demand.

Fixes:
- Fix `ForeignKeyTypeChecker` for newest SQLite.

Support:
- Ruby 2.4 and Ruby 2.5 are removed from CI but they should be still working fine.

Breaking changes:
- The priority of configuration has changed. Please see the [configuration file example](rails-example/.database_consistency.yml) for details.

### [1.1.15] - 2022/05/04

Improvements:
- For Ruby 2.7+ ignore models that come from Bundler.

### [1.1.14] - 2022/04/28

Fixes:
- `MissingIndexChecker` checks for precise unique indexes for `has_one` associations.

### [1.1.13] - 2022/04/28

Improvements:
- `MissingIndexChecker` checks for unique indexes for `has_one` associations. 

### [1.1.12] - 2022/01/23

Fixes:
- `ForeignKeyChecker` no longer check cases when model is part of another database. Thanks [Muhammad Usman](https://github.com/uxxman) for the contribution!

### [1.1.11] - 2022/01/15

Fixes:
- ColumnPresenceChecker no longer fails on `has_one :something, required: true`.

### [1.1.10] - 2022/01/06

Improvements:
- Allow aliases in YAML config file for Ruby 3.1. Thanks [jlestavel](https://github.com/jlestavel) for the contribution!

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
