For projects that use ActiveRecord, you can copy the following code and create a file `database_consistency_runner.rb`.

```ruby
# First of all, you need to load all models
# The following example is for Rails, but it can be anything
# require_relative 'config/environment'
# Rails.application.eager_load!

# Now start the check
config = ['.database_consistency.yml'] # default configuration, you can have many, just list it here

# Provide single or no option to the runner
options = {
  # Set this to true when you want to auto-fix issues instead
  # autofix: true,

  # Set this to true when you want to generate a TODO file instead
  # todo: true
}

require 'database_consistency'
result = DatabaseConsistency.run(config, **options)
exit result
```

Now, just start the script with:

```bash
$ bundle exec ruby database_consistency_runner
```
