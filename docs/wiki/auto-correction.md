The tool has an auto-correction option supported. You can run it with the following command:

```bash
$ bundle exec database_consistency -f
```

## Scoping auto-correction to specific checkers

Pair `--autofix` with `--only-checkers=LIST` to restrict auto-correction to a comma-separated list of checker class names. Offenses from every other checker are left untouched.

```bash
# Fix only ColumnPresenceChecker offenses:
$ bundle exec database_consistency --autofix --only-checkers=ColumnPresenceChecker

# Fix ColumnPresenceChecker and NullConstraintChecker offenses:
$ bundle exec database_consistency -f --only-checkers=ColumnPresenceChecker,NullConstraintChecker
```

Names must match the checker class name exactly (e.g. `ColumnPresenceChecker`, not `column_presence_checker`). Unknown names are rejected before any checks run, with a non-zero exit code and a list of the valid names. `--only-checkers` on its own (without `--autofix`) also exits with an error.
