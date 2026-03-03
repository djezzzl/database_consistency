## HABTM issue

### Question

HasAndBelongsToMany association outputs an issue:

```
fail HABTM_Categories article_id column is required in the database but do not have presence validator
```

but I don't have a model defined, how to fix it?

### Answer

That kind of model has no differences from others, so you can disable it from being explored by specifying the configuration like:

```yaml
# ...
HABTM_Categories:
  enabled: false
# ...
```
