# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::LengthConstraintChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }

  before do
    define_database_with_entity { |table| table.string :email, limit: 256 }
  end

  context 'when validation is missing' do
    let(:klass) { define_class { |klass| klass.validates :email, length: { maximum: 256 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'LengthConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when validation is missing' do
    let(:klass) { define_class }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'LengthConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        error_slug: :length_validator_missing,
        error_message: nil
      )
    end
  end

  context 'when validator length limit is smaller than limit in the database' do
    let(:klass) { define_class { |klass| klass.validates :email, length: { maximum: 100 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'LengthConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :warning,
        error_slug: :length_validator_greater_limit,
        error_message: nil
      )
    end
  end

  context 'when validator length limit is greater than limit in the database' do
    let(:klass) { define_class { |klass| klass.validates :email, length: { maximum: 300 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'LengthConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        error_slug: :length_validator_lower_limit,
        error_message: nil
      )
    end
  end
end
