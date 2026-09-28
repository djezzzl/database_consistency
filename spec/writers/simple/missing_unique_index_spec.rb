# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingUniqueIndex, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'email',
           error_message: nil,
           table_name: 'users',
           columns: ['email'])
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning unique index' do
    expect(writer.send(:template)).to include('unique index')
  end

  it 'returns unique_attributes with unique: true' do
    expect(writer.unique_key).to include(unique: true)
  end
end
