# frozen_string_literal: true

RSpec.describe(
  DatabaseConsistency::Writers::Simple::EnumValuesInconsistentWithInclusion,
  :sqlite, :mysql, :postgresql
) do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'status',
           error_message: nil,
           enum_values: %w[x y],
           declared_values: %w[z w])
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning inclusion validation' do
    expect(writer.send(:template)).to include('inclusion validation')
  end

  it 'formats enum_values and declared_values in the message' do
    expect(writer.msg).to include('x, y')
    expect(writer.msg).to include('z, w')
  end

  it 'returns unique_attributes with inclusion flag' do
    expect(writer.unique_key).to include(inclusion: true)
  end
end
