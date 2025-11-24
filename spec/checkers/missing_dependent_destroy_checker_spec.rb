# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingDependentDestroyChecker, :sqlite do
  subject(:checker) { described_class.new(model, association) }

  let(:model) { entity_class }
  let(:association) { entity_class.reflect_on_all_associations.first }
  let!(:entity_class) do
    define_class do |klass|
      klass.belongs_to :thing
    end
  end

  before do
    skip('older versions are not supported with sqlite3') if ActiveRecord::VERSION::MAJOR < 5 && adapter == 'sqlite3'
  end

  context 'when there is a foreign key constraint without a cascade' do
    before do
      define_database do
        create_table :things

        create_table :entities do |t|
          t.integer :thing_id
        end

        add_foreign_key :entities, :things
      end
    end

    context 'when there is a has_many association with a dependent clause' do
      let!(:thing_class) do
        define_class 'Thing', 'things' do |klass|
          klass.has_many :entities, dependent: :destroy
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingDependentDestroyChecker',
          model_name: thing_class.name,
          attribute_name: 'entities',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when there is a has_many association without a dependent clause' do
      let!(:thing_class) do
        define_class 'Thing', 'things' do |klass|
          klass.has_many :entities
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingDependentDestroyChecker',
          model_name: thing_class.name,
          attribute_name: 'entities',
          status: :fail,
          error_message: nil,
          error_slug: :missing_dependent_destroy
        )
      end
    end
  end

  context 'when there is a foreign key constraint with a cascade' do
    before do
      define_database do
        create_table :things

        create_table :entities do |t|
          t.integer :thing_id
        end

        add_foreign_key :entities, :things, on_delete: :cascade
      end
    end

    context 'when there is a has_many association without a dependent clause' do
      let!(:thing_class) do
        define_class 'Thing', 'things' do |klass|
          klass.has_many :entities
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingDependentDestroyChecker',
          model_name: thing_class.name,
          attribute_name: 'entities',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end
end
