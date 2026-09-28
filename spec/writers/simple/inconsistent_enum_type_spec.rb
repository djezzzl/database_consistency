# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::InconsistentEnumType, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'status',
           error_message: nil,
           values_types: %w[string integer],
           column_type: 'integer')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'includes values_types and column_type in message' do
    expect(writer.msg).to include('string, integer')
    expect(writer.msg).to include('integer')
  end

  it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
    expect(writer.unique_key).to include(
      table_or_model_name: 'users',
      column_or_attribute_name: 'status'
    )
  end
end
