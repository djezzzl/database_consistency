# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::AssociationMissingIndex, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'posts',
           column_or_attribute_name: 'user_id',
           error_message: nil,
           table_name: 'posts',
           columns: ['user_id'])
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning index' do
    expect(writer.send(:template)).to include('index')
  end

  it 'returns unique_attributes with table_name and columns' do
    expect(writer.unique_key).to include(table_name: 'posts', columns: ['user_id'])
  end
end
