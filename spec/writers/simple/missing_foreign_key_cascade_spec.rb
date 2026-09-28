# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingForeignKeyCascade, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'posts',
           column_or_attribute_name: 'user_id',
           error_message: nil,
           cascade_option: 'delete',
           foreign_table: 'posts',
           foreign_key: 'user_id',
           primary_table: 'users',
           primary_key: 'id')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'includes cascade_option in message' do
    expect(writer.msg).to include('delete')
  end

  it 'returns unique_attributes with cascade_option and foreign/primary table info' do
    expect(writer.unique_key).to include(
      cascade_option: 'delete',
      foreign_table: 'posts',
      foreign_key: 'user_id'
    )
  end
end
