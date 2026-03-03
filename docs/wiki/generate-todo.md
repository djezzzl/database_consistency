You can add the gem to your CI as soon as you install it. In order to postpone existing issues and slowly fix them, you can generate a TODO file automatically.

```bash
$ bundle exec database_consistency -g
```

This command will generate a `.database_consistency.todo.yml` file that will have disabled existing issues.

_Note: You have to manually send this configuration file to the runner if you want it to be used._

```bash
$ bundle exec database_consistency -c .database_consistency.todo.yml
```
