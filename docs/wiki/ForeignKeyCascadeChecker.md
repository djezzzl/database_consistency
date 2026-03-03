Imagine you have an association with the `:dependent` option. This means that every time a record is destroyed, the application expects associated data to also be affected depending on the option.

Unfortunately, since such a dependency call is based on callbacks, it could be simply skipped, meaning our expectations wouldn't be met. Fortunately, some of the options can be easily fixed by introducing corresponding cascade constraints on foreign keys at the database level.

Currently, supported options are:

- `delete`
- `delete_all`
- `nullify`
- `restrict_with_exception`
- `restrict_with_error`

There is nothing to be done with `destroy` or `destroy_async` options because database deletion can't invoke application callbacks.

If callbacks are not important, we highly recommend using `delete`/`delete_all` options instead.
