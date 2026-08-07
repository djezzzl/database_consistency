# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::DefaultMessage, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'TestChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'email',
           error_message: 'custom error',
           to_h: { custom: 'val' })
  end
  subject(:writer) { described_class.new(report, config: config) }

  it 'uses error_message as template' do
    expect(writer.send(:template)).to eq('custom error')
  end

  it 'uses report.to_h for unique_attributes' do
    expect(writer.unique_key).to include(custom: 'val')
  end
end
