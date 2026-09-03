# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::Base, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    double('report',
           checker_name: 'NullConstraintChecker',
           status: :fail,
           table_or_model_name: 'users',
           column_or_attribute_name: 'email',
           error_message: nil)
  end

  subject(:writer) { described_class.new(report, config: config) }

  describe '.with' do
    it 'creates a subclass with the given template' do
      klass = described_class.with('custom template text')
      instance = klass.new(report, config: config)
      expect(instance.send(:template)).to eq('custom template text')
    end
  end

  describe '#msg' do
    it 'includes checker name and key_text' do
      allow(writer).to receive(:template).and_return('')
      allow(writer).to receive(:unique_attributes).and_return({})
      expect(writer.msg).to include('NullConstraintChecker')
    end
  end

  describe '#unique_key' do
    it 'raises StandardError when unique_attributes is not implemented' do
      expect { writer.unique_key }.to raise_error(StandardError, 'Missing the implementation')
    end
  end

  describe 'colorize' do
    context 'when colored output is enabled' do
      before { allow(config).to receive(:colored?).and_return(true) }

      it 'wraps text with ANSI color codes' do
        result = writer.send(:colorize, 'hello', :red)
        expect(result).to include("\e[31m")
        expect(result).to include('hello')
        expect(result).to include("\e[0m")
      end
    end

    context 'when colored output is disabled' do
      before { allow(config).to receive(:colored?).and_return(false) }

      it 'returns plain text' do
        expect(writer.send(:colorize, 'hello', :red)).to eq('hello')
      end
    end

    context 'when text is nil' do
      before { allow(config).to receive(:colored?).and_return(true) }

      it 'returns nil' do
        expect(writer.send(:colorize, nil, :red)).to be_nil
      end
    end
  end

  describe '#status_text' do
    context 'when status is :fail' do
      before { allow(config).to receive(:colored?).and_return(false) }

      it 'returns the status symbol' do
        expect(writer.send(:status_text)).to eq(:fail)
      end
    end

    context 'when status is :ok' do
      let(:report) do
        double('report',
               checker_name: 'NullConstraintChecker',
               status: :ok,
               table_or_model_name: 'users',
               column_or_attribute_name: 'email',
               error_message: nil)
      end

      before { allow(config).to receive(:colored?).and_return(false) }

      it 'returns :ok' do
        expect(writer.send(:status_text)).to eq(:ok)
      end
    end
  end

  describe '#key_text' do
    before { allow(config).to receive(:colored?).and_return(false) }

    it 'combines table and column names' do
      expect(writer.send(:key_text)).to eq('users email')
    end

    context 'when column_or_attribute_name is nil' do
      let(:report) do
        double('report',
               checker_name: 'MissingTableChecker',
               status: :fail,
               table_or_model_name: 'orphan_model',
               column_or_attribute_name: nil,
               error_message: nil)
      end

      it 'returns only the table name' do
        expect(writer.send(:key_text)).to eq('orphan_model')
      end
    end
  end
end
