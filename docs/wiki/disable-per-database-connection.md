Since DatabaseConsistency version 1.7.12, given the `database.yml` configuration as follows:

```yaml
development:
  primary:
    <<: *default
    database: db/development.sqlite3
  secondary:
    <<: *default
    database: db/development_secondary.sqlite3
    migrations_paths: db/migrate_secondary
```

It is possible to disable all checks at once for the entire connection.

Just add the following configuration to your `.database_consistency.yml`

```yaml
# Configures database connections.
DatabaseConsistencyDatabases:
  # Database connection name listed in database.yml.
  secondary:
    enabled: false # disables any check for +secondary+ database.
```
