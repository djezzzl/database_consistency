# FAQ

#### 1. HABTM issue 

Q: HasAndBelongsToMany association outputs an issue:

```bash
fail HABTM_Categories article_id column is required in the database but do not have presence validator
```

but I don't have model defined, how to fix it?

A: Those kind of models have no differences with others, so you can disable it from being explored by
specifying [configuration](rails-example/.database_consistency.yml) like so:
```yaml
HABTM_Categories:
  enabled: false
```


