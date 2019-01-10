# frozen_string_literal: true

RSpec.shared_context 'database context' do
  def define_database(&block)
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )
    ActiveRecord::Schema.verbose = false

    ActiveRecord::Schema.define(version: 1, &block)
  end

  def define_database_with_entity
    define_database do
      create_table :entities, id: false do |table|
        yield(table) if block_given?
      end
    end
  end

  def define_class(name = 'Entity', table_name = :entities)
    Class.new(ActiveRecord::Base) do |klass|
      klass.define_singleton_method :name do
        name
      end

      klass.table_name = table_name
      yield(klass) if block_given?
    end
  end
end
