# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingAssociationClass, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'profile',
           error_message: nil,
           class_name: 'Profile')
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'includes class_name in message' do
    expect(writer.msg).to include('Profile')
  end

  it 'returns unique_attributes with class_name' do
    expect(writer.unique_key).to include(class_name: 'Profile')
  end
end
