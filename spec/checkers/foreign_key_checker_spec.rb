# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ForeignKeyChecker do
  subject(:checker) { described_class.new(model, association) }

  let(:model) { entity_class }
  let(:association) { entity_class.reflect_on_all_associations.first }
  let!(:country_class) { define_class('Country', :countries) }
  let!(:entity_class) do
    define_class do |klass|
      klass.belongs_to :country
    end
  end

  test_each_database do
    before do
      skip('older versions are not supported with sqlite3') if ActiveRecord::VERSION::MAJOR < 5 && adapter == 'sqlite3'
    end

    context 'when foreign key is provided' do
      before do
        define_database do
          create_table :countries

          create_table :entities do |t|
            if ActiveRecord::VERSION::MAJOR >= 5 && adapter == 'mysql2'
              t.bigint :country_id
            else
              t.integer :country_id
            end

            t.foreign_key :countries
          end
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ForeignKeyChecker',
          table_or_model_name: entity_class.name,
          column_or_attribute_name: 'country',
          status: :ok,
          message: nil
        )
      end
    end

    context 'when foreign key is missing' do
      before do
        define_database do
          create_table :countries

          create_table :entities do |t|
            t.integer :country_id
          end
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ForeignKeyChecker',
          table_or_model_name: entity_class.name,
          column_or_attribute_name: 'country',
          status: :fail,
          message: 'should have foreign key in the database'
        )
      end
    end

    context 'when association is different than belongs_to' do
      let!(:entity_class) do
        define_class do |klass|
          klass.has_one :country
        end
      end

      specify do
        expect(checker.report).to be_nil
      end
    end

    context 'when association is polymorphic' do
      let!(:entity_class) do
        define_class do |klass|
          klass.belongs_to :country, polymorphic: true
        end
      end

      specify do
        expect(checker.report).to be_nil
      end
    end
  end
end
