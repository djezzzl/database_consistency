# frozen_string_literal: true

RSpec.shared_examples 'match' do
  it 'matches' do
    expect(checker.report).to have_attributes(
      checker_name: 'ForeignKeyTypeChecker',
      table_or_model_name: company_class.name,
      column_or_attribute_name: association.name.to_s,
      status: :ok,
      message: nil
    )
  end
end

RSpec.shared_examples 'mismatch' do
  it 'mismatches' do
    expect(checker.report).to have_attributes(
      checker_name: 'ForeignKeyTypeChecker',
      table_or_model_name: company_class.name,
      column_or_attribute_name: association.name.to_s,
      status: :fail,
      message: /foreign key (.*) with type (.*) doesn't cover primary key (.*) with type (.*)/
    )
  end
end
