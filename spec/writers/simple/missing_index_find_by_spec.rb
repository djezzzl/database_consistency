# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingIndexFindBy, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }

  context 'without source_location' do
    let(:report) do
      double('report',
             checker_name: 'TestChecker',
             status: :fail,
             table_or_model_name: 'users',
             column_or_attribute_name: 'email',
             error_message: nil,
             source_location: nil,
             total_findings_count: nil)
    end
    subject(:writer) { described_class.new(report, config: config) }

    it 'has a message without source location' do
      expect(writer.msg).to include('find_by')
      expect(writer.msg).not_to include('found at')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  context 'with source_location' do
    let(:report) do
      double('report',
             checker_name: 'TestChecker',
             status: :fail,
             table_or_model_name: 'users',
             column_or_attribute_name: 'email',
             error_message: nil,
             source_location: 'app/models/user.rb:10',
             total_findings_count: 1)
    end
    subject(:writer) { described_class.new(report, config: config) }

    it 'includes source_location in message' do
      expect(writer.msg).to include('app/models/user.rb:10')
    end
  end

  context 'with multiple findings' do
    let(:report) do
      double('report',
             checker_name: 'TestChecker',
             status: :fail,
             table_or_model_name: 'users',
             column_or_attribute_name: 'email',
             error_message: nil,
             source_location: 'app/models/user.rb:10',
             total_findings_count: 3)
    end
    subject(:writer) { described_class.new(report, config: config) }

    it 'mentions additional findings count' do
      expect(writer.msg).to include('and 2 more')
    end
  end
end
