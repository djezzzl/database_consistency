The tool has an auto-correction option supported. You can run it with the following command:

```bash
$ bundle exec database_consistency -f
```

## Scoping auto-correction to specific checkers

`-f` optionally accepts a comma-separated list of checker class names. Only offenses produced by the listed checkers are auto-corrected; other offenses are left untouched.

```bash
# Fix only ColumnPresenceChecker offenses:
$ bundle exec database_consistency -f ColumnPresenceChecker

# Fix ColumnPresenceChecker and NullConstraintChecker offenses:
$ bundle exec database_consistency -f ColumnPresenceChecker,NullConstraintChecker
```

Unknown checker names are rejected with a non-zero exit code and a list of the valid names.
