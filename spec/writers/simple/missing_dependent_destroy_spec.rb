# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingDependentDestroy, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'Company',
           column_or_attribute_name: 'users',
           error_message: nil,
           model_name: 'Company',
           attribute_name: 'users')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning dependent' do
    expect(writer.send(:template)).to include('dependent')
  end

  it 'returns unique_attributes with model_name and attribute_name' do
    expect(writer.unique_key).to include(model_name: 'Company', attribute_name: 'users')
  end
end
