# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::NullConstraintChecker do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }

  test_each_database do
    before do
      define_database_with_entity { |table| table.string :email, null: false }
    end

    context 'when validation is missing' do
      let(:klass) { define_class }

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'NullConstraintChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          message: 'column is required in the database but do not have presence validator'
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
          message: nil
        )
      end
    end
  end
end
