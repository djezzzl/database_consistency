# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::LengthConstraintChecker do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }

  test_each_database do
    before do
      define_database_with_entity { |table| table.string :email, limit: 256 }
    end

    context 'when validation is missing' do
      let(:klass) { define_class }

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'LengthConstraintChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          message: 'column has limit in the database but do not have length validator'
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
          message: 'column has greater limit in the database than in length validator'
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
          message: 'column has lower limit in the database than in length validator'
        )
      end
    end
  end
end
