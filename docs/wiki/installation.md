Add this line to your application's Gemfile:

```ruby
gem 'database_consistency', group: :development, require: false
```

And then execute:

```bash
$ bundle install
```

Run the installer to generate the default configuration to exclude false positives caused by some popular libraries:

```bash
$ bundle exec database_consistency install
```

You can also generate a TODO file that will ignore existing issues in your project:

```bash
$ bundle exec database_consistency -g
```
