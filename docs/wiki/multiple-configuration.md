You can have multiple configuration files. This is useful when you have many teams owning different files and you want them to own their configuration files separately and slowly address the issues.

You can pass multiple configurations with the following command.

```bash
$ bundle exec database_consistency -c .database_consistency.team1.yml -c .database_consistency.team2.yml
```

If multiple configurations have the same rule, the latest has the highest priority.
