# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ForeignKeyCascadeChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, association) }

  let(:model) { entity_class }
  let(:association) { entity_class.reflect_on_all_associations.first }
  let!(:country_class) { define_class('Country', :countries) }

  before do
    skip('older versions are not supported with sqlite3') if ActiveRecord::VERSION::MAJOR < 5 && adapter == 'sqlite3'
  end

  context 'when there is no cascade' do
    before do
      define_database do
        create_table :entities

        create_table :countries do |t|
          if ActiveRecord::VERSION::MAJOR >= 5 && adapter == 'mysql2'
            t.bigint :entity_id
          else
            t.integer :entity_id
          end

          t.foreign_key :entities
        end
      end
    end

    context 'when dependent option is missing' do
      let!(:entity_class) do
        define_class('Entity', :entities) do |klass|
          klass.has_many :countries, dependent: :delete_all
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ForeignKeyCascadeChecker',
          table_or_model_name: entity_class.name,
          column_or_attribute_name: 'countries',
          status: :fail,
          error_message: nil,
          error_slug: :missing_foreign_key_cascade
        )
      end
    end
  end

  context 'with cascade option' do
    before do
      define_database do
        create_table :entities

        create_table :countries do |t|
          if ActiveRecord::VERSION::MAJOR >= 5 && adapter == 'mysql2'
            t.bigint :entity_id
          else
            t.integer :entity_id
          end

          t.foreign_key :entities, on_delete: :cascade
        end
      end
    end

    context 'when dependent option is missing' do
      let!(:entity_class) do
        define_class('Entity', :entities) do |klass|
          klass.has_one :country
        end
      end

      specify do
        expect(checker.report).to be_nil
      end
    end

    context 'when dependent option matches' do
      let!(:entity_class) do
        define_class('Entity', :entities) do |klass|
          klass.has_one :country, dependent: :delete
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ForeignKeyCascadeChecker',
          table_or_model_name: entity_class.name,
          column_or_attribute_name: 'country',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when dependent option mismatches' do
      let!(:entity_class) do
        define_class('Entity', :entities) do |klass|
          klass.has_one :country, dependent: :nullify
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ForeignKeyCascadeChecker',
          table_or_model_name: entity_class.name,
          column_or_attribute_name: 'country',
          status: :fail,
          error_message: nil,
          error_slug: :missing_foreign_key_cascade
        )
      end
    end
  end
end
