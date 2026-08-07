# frozen_string_literal: true

RSpec.describe(
  DatabaseConsistency::Writers::Simple::NullConstraintAssociationMissesValidator,
  :sqlite, :mysql, :postgresql
) do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'company_id',
           error_message: nil,
           association_name: 'company')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'includes association_name in message' do
    expect(writer.msg).to include('company')
  end

  it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
    expect(writer.unique_key).to include(
      table_or_model_name: 'users',
      column_or_attribute_name: 'company_id'
    )
  end
end
