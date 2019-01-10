# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::BelongsToPresenceChecker do
  subject(:checker) { described_class.new(model, attribute, validator) }

  before do
    skip('older versions are not supported with sqlite3') if ActiveRecord::VERSION::MAJOR < 5
  end

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

  include_context 'database context'

  context 'when foreign key is provided' do
    before do
      define_database do
        create_table :countries

        create_table :entities do |t|
          t.integer :country_id, null: false
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

  context 'when foreign key is missed' do
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
        message: 'should have foreign key in the database'
      )
    end
  end
end
