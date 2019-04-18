# frozen_string_literal: true

RSpec.shared_context 'database context' do |configuration|
  before do
    ActiveRecord::Base.establish_connection(configuration)
    clear_database!
    ActiveRecord::Schema.verbose = false
  end

  define_method :define_database do |&block|
    ActiveRecord::Schema.define(version: 1, &block)
  end

  define_method :define_database_with_entity do |&block|
    define_database do
      create_table(:entities, id: false, &block)
    end
  end

  define_method :clear_database! do
    ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=0;' if configuration[:adapter] == 'mysql2'
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table, force: :cascade)
    end
    ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=1;' if configuration[:adapter] == 'mysql2'
  end

  def define_class(name = 'Entity', table_name = :entities)
    stub_const(name, Class.new(ActiveRecord::Base) do |klass|
      klass.define_singleton_method :name do
        name
      end

      klass.table_name = table_name
      yield(klass) if block_given?
    end)
  end
end

RSpec.shared_context 'postgresql database context' do
  include_context 'database context', adapter: 'postgresql', database: 'database_consistency_test'
end
