# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::RedundantIndex, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'email',
           error_message: nil,
           covered_index_name: 'index_users_on_email_and_name',
           index_name: 'index_users_on_email')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'includes covered_index_name in message' do
    expect(writer.msg).to include('index_users_on_email_and_name')
  end

  it 'returns unique_attributes with index_name' do
    expect(writer.unique_key).to include(index_name: 'index_users_on_email')
  end
end
