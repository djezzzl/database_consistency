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

  shared_examples 'global checker' do |value|
    context 'global checker' do
      specify do
        expect(configuration.enabled?('DatabaseConsistencyCheckers', 'ColumnPresenceChecker')).to eq(value)
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
    include_examples 'key', true
    include_examples 'checker', true
  end

  context 'when key is disabled' do
    let(:file_path) { 'key_disabled.yml' }

    include_examples 'model', true
    include_examples 'key', false
    include_examples 'checker', true

    context 'when compact' do
      let(:file_path) { 'compact_checker_disabled.yml' }

      include_examples 'model', true
      include_examples 'key', true
      include_examples 'checker', false
    end
  end

  context 'with all option enabled' do
    let(:file_path) { 'all_enabled.yml' }

    include_examples 'global checker', true
    include_examples 'model', true
    include_examples 'key', true
    include_examples 'checker', false
  end

  context 'with all option disabled' do
    let(:file_path) { 'all_disabled.yml' }

    include_examples 'global checker', true
    include_examples 'model', false
    include_examples 'key', false
    include_examples 'checker', true
  end

  context 'with YAML alias' do
    let(:file_path) { 'alias.yml' }

    include_examples 'model', true
    include_examples 'key', false
    include_examples 'checker', true
  end

  context 'when multiple files are given' do
    subject(:configuration) do
      described_class.new([
                            file_fixture('compact_checker_disabled.yml'),
                            file_fixture('todo.yml'),
                            file_fixture('todo_override.yml')
                          ])
    end

    it 'merges settings with last one given having the highest priority' do
      expect(configuration).not_to be_enabled('User', 'email', 'ColumnPresenceChecker')
      expect(configuration).not_to be_enabled('User', 'code', 'MissingIndexChecker')
      expect(configuration).not_to be_enabled('User', 'data', 'MissingIndexChecker')
      expect(configuration).to be_enabled('User', 'code', 'NullConstraintChecker')
    end
  end
end
