Configuration example for [overcommit](https://github.com/brigade/overcommit) gem.

```yaml
PreCommit:
  DatabaseConsistency:
    enabled: true
    quiet: false
    command: ['bundle', 'exec', 'database_consistency']
```
