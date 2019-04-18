# Changelog

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
