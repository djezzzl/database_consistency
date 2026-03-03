The library supports flexible configuration. The example below should give you a clue on how you can turn on and off some of its functionality.

```yaml
DatabaseConsistencySettings:
  color: true # Brings color tags to console output.
  log_level: DEBUG # Sets the log level. DEBUG outputs all checks including those that successfully passed.

# Configures database connections since version 1.7.12.
DatabaseConsistencyDatabases:
  # Database connection name listed in database.yml.
  secondary:
    enabled: false # disables any check for +secondary+ database.

# Every checker is enabled by default.
DatabaseConsistencyCheckers:
  All:
    enabled: true # You can disable everything until you explicitly enable it.
  MissingIndexChecker:
    enabled: true # Enables/disables the checker entirely/globally. If disabled here, nothing can enable it back.
  MissingUniqueIndexChecker:
    enabled: true
  ColumnPresenceChecker:
    enabled: true
  NullConstraintChecker:
    enabled: true

User:
  enabled: true # Enables/disables checks for the whole model. This can be overwritten by a deeper configuration (the latest configuration has the highest priority).
  phone:
    enabled: true # Enables/disables checks for the field. This can be overwritten by a deeper configuration (the latest configuration has the highest priority).
    ColumnPresenceChecker:
      enabled: true # Enables/disables specific checker for the field. This has the highest priority (except for globally disabled checkers).
  name:
    enabled: true
  code:
    enabled: true
    NullConstraintChecker:
      enabled: true
  name+email: # index can be specified by its columns in some checkers
    MissingUniqueIndexChecker:
      enabled: true
  index_users_on_less_password_token: # index can be specified by its name for some checkers
    UniqueIndexChecker:
      enabled: false

Country:
  users:
    MissingIndexChecker:
      enabled: true

# Can be compact (example), "enabled: true" is default
# User:
#   phone:
#     ColumnPresenceChecker:
#       enabled: false
#   name:
#     enabled: false
# Company:
#   enabled: false

# Since version 1.7.10 configuration supports * (asterisk) which is converted to `.*` and wrapped by Regexp.
# This can help you keep your configuration smaller and cleaner.

Namespace*: # models with this prefix (except those that have precise definitions without regexp) will follow this configuration
  enabled: false

Account:
  *_at: # columns with this suffix (except those that have precise definitions without regexp) will follow this configuration
    enabled: false

# Concerns can be emulated using YAML's anchors and aliases

# 1. Define an anchor before declaring concern-related settings
DateConcern: &ignore_date_concern
  date:
    NullConstraintChecker:
      enabled: false
NameConcern: &ignore_name_concern
  name:
    ColumnPresenceChecker:
      enabled: false

# Models using concerns
# 2. Now include the relevant settings using aliases
Event:
  <<: *ignore_date_concern
  <<: *ignore_name_concern
Poll:
  <<: *ignore_date_concern
```
