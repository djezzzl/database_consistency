Here's an example of integrating a custom checker ([source](https://github.com/djezzzl/database_consistency/pull/239)).

```ruby
# Gemfile

gem 'database_consistency', group: :development, require: false
```

```yaml
# .database_consistency.yml

require:
  - ./lib/database_consistency/checkers/enum_column_checker
```

```ruby
# lib/database_consistency/checkers/enum_column_checker.rb

require_relative "../writers/simple/enum_column_type_mismatch"

module DatabaseConsistency
  module Checkers
    # This class checks that ActiveRecord enum is backed by enum column
    class EnumColumnChecker < EnumChecker
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :table_name,
        :column_name
      )

      private

      # ActiveRecord supports native enum type since version 7 and only for PostgreSQL
      def preconditions
        Helper.postgresql? && ActiveRecord::VERSION::MAJOR >= 7 && column.present?
      end

      def check
        if valid?
          report_template(:ok)
        else
          report_template(:fail, error_slug: :enum_column_type_mismatch)
        end
      end

      def report_template(status, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: nil,
          table_name: model.table_name,
          column_name: column.name,
          **report_attributes
        )
      end

      def column
        @column ||= model.columns.find { |c| c.name.to_s == enum.to_s }
      end

      # @return [Boolean]
      def valid?
        column.type == :enum
      end
    end
  end
end
```

```ruby
# lib/database_consistency/writers/simple/enum_column_type_mismatch.rb

module DatabaseConsistency
  module Writers
    module Simple
      class EnumColumnTypeMismatch < Base # :nodoc:
        private

        def template
          "column should be enum type"
        end

        def unique_attributes
          {
            table_name: report.table_name,
            column_name: report.column_name
          }
        end
      end
    end
  end
end
```

```ruby
# db/migrate/20240914001835_create_things.rb

class CreateThings < ActiveRecord::Migration[7.2]
  def change
    create_table :things do |t|
      t.string :name, null: false
      t.string :status, default: 'active', null: false

      t.timestamps
    end
  end
end
```

```ruby
# app/models/thing.rb

class Thing < ApplicationRecord
  enum status: { active: "active", inactive: "inactive" }
end
```

```
$ bundle exec database_consistency
Loaded configurations: .database_consistency.yml
EnumColumnChecker fail Thing status column should be enum type
```
