# frozen_string_literal: true

RSpec.describe DatabaseConsistency::FilesHelper, :sqlite, :mysql, :postgresql do
  describe '.source_file_path' do
    it 'returns nil when mod.name raises StandardError' do
      mod = Module.new
      allow(mod).to receive(:name).and_raise(NotImplementedError, 'Class must implement the name method')
      expect(described_class.source_file_path(mod)).to be_nil
    end

    it 'returns nil when mod.name returns nil' do
      mod = Module.new
      expect(described_class.source_file_path(mod)).to be_nil
    end
  end

  describe '.collect_source_files' do
    it 'does not raise when a class overrides .name to raise an error' do
      mod = Module.new
      allow(mod).to receive(:name).and_raise(NotImplementedError, 'Class must implement the name method')
      allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(mod)
      expect { described_class.collect_source_files }.not_to raise_error
    end
  end
end
