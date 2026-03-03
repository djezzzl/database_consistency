Since version 1.7.10, you can keep your `.database_consistency.yml` configuration cleaner.

```yaml
# Configuration supports * (asterisk) which is converted to `.*` and wrapped by Regexp.
# This can help you keep your configuration smaller and cleaner.

Namespace*: # models with this prefix (except those that have precise definitions without regexp) will follow this configuration
  enabled: false

Account:
  *_at: # columns with this suffix (except those that have precise definitions without regexp) will follow this configuration
    enabled: false
```
