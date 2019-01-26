# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::NullConstraintChecker do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }

  test_each_database do
    context 'when validation is missing' do
      before do
        define_database_with_entity { |table| table.string :email, null: false }
      end

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
  end
end
