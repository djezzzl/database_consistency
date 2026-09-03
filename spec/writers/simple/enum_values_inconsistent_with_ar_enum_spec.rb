# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::EnumValuesInconsistentWithArEnum, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'status',
           error_message: nil,
           enum_values: %w[a b],
           declared_values: %w[c d])
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning ActiveRecord enum' do
    expect(writer.send(:template)).to include('ActiveRecord enum')
  end

  it 'formats enum_values and declared_values in the message' do
    expect(writer.msg).to include('a, b')
    expect(writer.msg).to include('c, d')
  end

  it 'returns unique_attributes with ar_enum flag' do
    expect(writer.unique_key).to include(ar_enum: true)
  end
end
