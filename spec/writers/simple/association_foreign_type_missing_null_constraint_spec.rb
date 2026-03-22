# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::AssociationForeignTypeMissingNullConstraint, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'email',
           error_message: nil,
           table_name: 'users',
           column_name: 'user_type')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning NOT NULL' do
    expect(writer.send(:template)).to include('NOT NULL')
  end

  it 'returns unique_attributes with table_name and column_name' do
    expect(writer.unique_key).to include(table_name: 'users', column_name: 'user_type')
  end
end
