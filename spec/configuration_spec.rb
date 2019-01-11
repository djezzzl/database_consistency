# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Configuration do
  subject(:configuration) { described_class.new(file_fixture(file_path)) }

  shared_examples 'checker' do |value|
    context 'checker' do
      specify do
        expect(configuration.enabled?('User', 'email', 'ColumnPresenceChecker')).to eq(value)
      end
    end
  end

  shared_examples 'model' do |value|
    context 'model' do
      specify do
        expect(configuration.enabled?('User')).to eq(value)
      end
    end
  end

  shared_examples 'key' do |value|
    context 'key' do
      specify do
        expect(configuration.enabled?('User', 'email')).to eq(value)
      end
    end
  end

  context 'when checker is disabled' do
    let(:file_path) { 'checker_disabled.yml' }

    include_examples 'model', true
    include_examples 'key', true
    include_examples 'checker', false
  end

  context 'when model is disabled' do
    let(:file_path) { 'model_disabled.yml' }

    include_examples 'model', false
    include_examples 'key', false
    include_examples 'checker', false
  end

  context 'when key is disabled' do
    let(:file_path) { 'key_disabled.yml' }

    include_examples 'model', true
    include_examples 'key', false
    include_examples 'checker', false

    context 'when compact' do
      let(:file_path) { 'compact_checker_disabled.yml' }

      include_examples 'model', true
      include_examples 'key', true
      include_examples 'checker', false
    end
  end
end
