# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingForeignKey, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'posts',
           column_or_attribute_name: 'user_id',
           error_message: nil,
           foreign_table: 'posts',
           foreign_key: 'user_id',
           primary_table: 'users',
           primary_key: 'id')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'has a template mentioning foreign key' do
    expect(writer.send(:template)).to include('foreign key')
  end

  it 'returns unique_attributes with foreign and primary table info' do
    expect(writer.unique_key).to include(
      foreign_table: 'posts', foreign_key: 'user_id',
      primary_table: 'users', primary_key: 'id'
    )
  end
end
