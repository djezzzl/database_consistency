After checking out the repo, run `bundle install` to install dependencies. You need to have installed and running `postgresql` and `mysql`. And for each adapter manually create a database called `database_consistency_test` accessible by your local user.

## MySQL

`user` is your local user from `$whoami` command

```sql
mysql -uroot --password
mysql> CREATE DATABASE database_consistency_test;
mysql> CREATE USER user@localhost IDENTIFIED BY '';
mysql> GRANT ALL PRIVILEGES ON database_consistency_test.* TO user@localhost;
```

## PostgreSQL

```bash
$ psql postgres
postgres=# CREATE DATABASE database_consistency_test;
```

Then, run `DATABASE=adapter_name bundle exec rspec` to run the tests for the specified database. Available options are:

```
mysql
postgresql
sqlite
```

Default is `sqlite`.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org/).
