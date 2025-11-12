# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::NullConstraintChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }

  before do
    define_database_with_entity do |table|
      table.string :email, null: false
      table.integer :count, null: false
    end
  end

  context 'when validation is missing' do
    let(:klass) { define_class }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NullConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        error_slug: :null_constraint_misses_validator,
        error_message: nil
      )
    end
  end

  context 'when has exclusion validation with nil' do
    let(:klass) { define_class { |klass| klass.validates_exclusion_of :email, in: [nil] } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NullConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when has belongs_to association' do
    if ActiveRecord::VERSION::MAJOR >= 5
      required = { optional: false }
      optional = { optional: true }
    else
      required = { required: true }
      optional = { required: false }
    end

    before do
      define_database do
        create_table :companies, id: false do |t|
          t.integer :user_id, null: false
        end
      end
    end

    context 'when association is required' do
      let(:klass) { define_class('Company', :companies) { |klass| klass.belongs_to :user, **required } }

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'NullConstraintChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'user_id',
          status: :ok,
          error_slug: nil,
          error_message: nil
        )
      end
    end

    context 'when association is optional ' do
      let(:klass) { define_class('Company', :companies) { |klass| klass.belongs_to :user, **optional } }

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'NullConstraintChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'user_id',
          status: :fail,
          error_slug: :null_constraint_association_misses_validator,
          error_message: nil,
          association_name: 'user'
        )
      end
    end
  end

  context 'when has numericality validation with allow_nil' do
    let(:klass) { define_class { |klass| klass.validates_numericality_of :count, allow_nil: true } }
    subject(:checker) { described_class.new(model, klass.columns.last) }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NullConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'count',
        status: :fail,
        error_slug: :null_constraint_misses_validator,
        error_message: nil
      )
    end
  end

  context 'when has numericality validation without allow_nil' do
    let(:klass) { define_class { |klass| klass.validates_numericality_of :count } }
    subject(:checker) { described_class.new(model, klass.columns.last) }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NullConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'count',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when has exclusion validation with Proc { [nil] }' do
    let(:klass) { define_class { |klass| klass.validates_exclusion_of :email, in: -> { [nil] } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NullConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when has exclusion validation with Proc { ["something"] }' do
    let(:klass) { define_class { |klass| klass.validates_exclusion_of :email, in: -> { ['something'] } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NullConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        error_slug: :null_constraint_misses_validator,
        error_message: nil
      )
    end
  end
end
