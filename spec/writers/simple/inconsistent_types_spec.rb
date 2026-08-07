# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::InconsistentTypes, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'posts',
           column_or_attribute_name: 'user_id',
           error_message: nil,
           fk_name: 'user_id',
           fk_type: 'integer',
           pk_name: 'id',
           pk_type: 'bigint',
           table_to_change: 'posts',
           type_to_set: 'bigint')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'includes fk/pk names and types in message' do
    expect(writer.msg).to include('user_id')
    expect(writer.msg).to include('integer')
    expect(writer.msg).to include('bigint')
  end

  it 'returns unique_attributes with table_to_change and fk_name' do
    expect(writer.unique_key).to include(table_to_change: 'posts', fk_name: 'user_id')
  end
end
