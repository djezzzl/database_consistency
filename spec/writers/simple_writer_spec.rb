# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::SimpleWriter, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }

  def build_report(status:, error_slug: nil, error_message: nil, table_or_model_name: 'users',
                   column_or_attribute_name: 'email', checker_name: 'NullConstraintChecker')
    double('report',
           status: status,
           error_slug: error_slug,
           error_message: error_message,
           table_or_model_name: table_or_model_name,
           column_or_attribute_name: column_or_attribute_name,
           checker_name: checker_name,
           to_h: { checker_name: checker_name, table_or_model_name: table_or_model_name,
                   column_or_attribute_name: column_or_attribute_name })
  end

  describe '#write' do
    subject(:write) { described_class.write(reports, config: config) }

    context 'when there are no reports' do
      let(:reports) { [] }

      it 'does not raise' do
        expect { write }.not_to raise_error
      end
    end

    context 'when report status is ok' do
      let(:reports) { [build_report(status: :ok)] }

      it 'does not print anything' do
        expect { write }.not_to output(/NullConstraintChecker/).to_stdout
      end
    end

    context 'when report status is fail' do
      let(:reports) { [build_report(status: :fail, error_message: 'some error')] }

      it 'prints a message' do
        expect { write }.to output(/NullConstraintChecker/).to_stdout
      end
    end

    context 'when report has a known error_slug' do
      let(:reports) { [build_report(status: :fail, error_slug: :null_constraint_missing)] }

      before do
        allow(reports.first).to receive(:table_name).and_return('users')
        allow(reports.first).to receive(:column_name).and_return('email')
      end

      it 'prints a message using the specific writer' do
        expect { write }.to output(/NullConstraintChecker/).to_stdout
      end
    end

    context 'when report has an unknown error_slug' do
      let(:reports) { [build_report(status: :fail, error_slug: :unknown_slug_xyz, error_message: 'fallback msg')] }

      it 'uses the default message writer' do
        expect { write }.to output(/NullConstraintChecker/).to_stdout
      end
    end

    context 'when multiple reports have the same unique_key' do
      let(:report1) { build_report(status: :fail, error_message: 'msg') }
      let(:report2) { build_report(status: :fail, error_message: 'msg') }
      let(:reports) { [report1, report2] }

      it 'groups and shows total count' do
        expect { write }.to output(/Total grouped offenses: 2/).to_stdout
      end
    end

    context 'when debug mode is enabled' do
      let(:config) do
        c = DatabaseConsistency::Configuration.new
        allow(c).to receive(:debug?).and_return(true)
        c
      end

      let(:reports) { [build_report(status: :ok, error_message: 'debug info')] }

      it 'prints ok reports too' do
        expect { write }.to output(/NullConstraintChecker/).to_stdout
      end
    end
  end
end
