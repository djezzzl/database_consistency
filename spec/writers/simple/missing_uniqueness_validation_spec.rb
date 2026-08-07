# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingUniquenessValidation, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'email',
           error_message: nil)
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning uniqueness validator' do
    expect(writer.send(:template)).to include('uniqueness validator')
  end

  it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
    expect(writer.unique_key).to include(
      table_or_model_name: 'users',
      column_or_attribute_name: 'email'
    )
  end
end
