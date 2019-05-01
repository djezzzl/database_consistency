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

  shared_examples 'namespaced model' do |value|
    context 'model' do
      specify do
        expect(configuration.enabled?('Namespace::Model')).to eq(value)
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

  context 'when file is empty' do
    let(:file_path) { 'empty.yml' }

    include_examples 'model', true
    include_examples 'key', true
    include_examples 'checker', true
  end

  context 'when checker is disabled' do
    let(:file_path) { 'checker_disabled.yml' }

    include_examples 'model', true
    include_examples 'key', true
    include_examples 'checker', false
  end

  context 'with namespaced model' do
    context 'when enabled' do
      let(:file_path) { 'namespaced_model_enabled.yml' }
      include_examples 'namespaced model', true
    end

    context 'when disabled' do
      let(:file_path) { 'namespaced_model_disabled.yml' }
      include_examples 'namespaced model', false
    end
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
