# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::BelongsToPresenceChecker do
  subject(:checker) { described_class.new(model, attribute, validator) }

  let(:model) { entity_class }
  let(:attribute) { :country }
  let(:validator) { entity_class.validators.first }
  let!(:country_class) { define_class('Country', :countries) }
  let!(:entity_class) do
    define_class do |klass|
      klass.belongs_to :country
      klass.validates :country, presence: true
    end
  end

  test_each_database do
    before do
      if ActiveRecord::VERSION::MAJOR < 5 && ActiveRecord::Base.connection_config[:adapter] == 'sqlite3'
        skip('older versions are not supported with sqlite3')
      end
    end

    context 'when foreign key is provided' do
      before do
        define_database do
          create_table :countries

          create_table :entities do |t|
            if ActiveRecord::VERSION::MAJOR >= 5 && ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
              t.bigint :country_id, null: false
            else
              t.integer :country_id, null: false
            end

            t.foreign_key :countries
          end
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'BelongsToPresenceChecker',
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
            t.integer :country_id, null: false
          end
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'BelongsToPresenceChecker',
          table_or_model_name: entity_class.name,
          column_or_attribute_name: 'country',
          status: :fail,
          message: 'model should have proper foreign key in the database'
        )
      end
    end

    context 'when association is different than belongs_to' do
      let!(:entity_class) do
        define_class do |klass|
          klass.has_one :country
          klass.validates :country, presence: true
        end
      end

      specify do
        expect(checker.report).to be_nil
      end
    end
  end
end
