The checker ensures that every unique validation on case-insensitive types (such as `citext` in `PostgreSQL`) doesn't have `case_sensitive: false` option.

This is needed to avoid the redundant `LOWER()` function on the query and index.
