# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingTable, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: nil,
           error_message: nil)
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning table' do
    expect(writer.send(:template)).to include('table')
  end

  it 'returns unique_attributes with table_or_model_name' do
    expect(writer.unique_key).to include(table_or_model_name: 'users')
  end
end
