# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::TodoWriter, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }

  def build_report(status:, table_or_model_name: 'users', column_or_attribute_name: 'email',
                   checker_name: 'NullConstraintChecker')
    double('report',
           status: status,
           table_or_model_name: table_or_model_name,
           column_or_attribute_name: column_or_attribute_name,
           checker_name: checker_name)
  end

  describe '#write' do
    subject(:write) { described_class.write(reports, config: config) }

    let(:todo_file) { '.database_consistency.todo.yml' }

    before do
      allow(File).to receive(:write)
      allow(File).to receive(:exist?).and_return(false)
    end

    context 'when there are no reports' do
      let(:reports) { [] }

      it 'writes an empty YAML file' do
        write
        expect(File).to have_received(:write).with(todo_file, "--- {}\n")
      end
    end

    context 'when report status is ok' do
      let(:reports) { [build_report(status: :ok)] }

      it 'does not include ok reports in the file' do
        write
        expect(File).to have_received(:write).with(todo_file, "--- {}\n")
      end
    end

    context 'when report status is fail' do
      let(:reports) { [build_report(status: :fail)] }

      it 'writes the failing report to the YAML file' do
        write
        expect(File).to have_received(:write).with(
          todo_file,
          include('users')
        )
      end

      it 'sets enabled to false for the checker' do
        write
        expect(File).to have_received(:write).with(
          todo_file,
          include('enabled: false')
        )
      end
    end

    context 'when there are multiple failing reports' do
      let(:reports) do
        [
          build_report(status: :fail, table_or_model_name: 'users', column_or_attribute_name: 'email',
                       checker_name: 'NullConstraintChecker'),
          build_report(status: :fail, table_or_model_name: 'companies', column_or_attribute_name: 'name',
                       checker_name: 'LengthConstraintChecker')
        ]
      end

      it 'writes all failing reports sorted alphabetically' do
        write
        expect(File).to have_received(:write) do |_file, content|
          parsed = YAML.safe_load(content)
          expect(parsed.keys).to eq(%w[companies users])
        end
      end
    end

    context 'when todo file already exists' do
      before do
        allow(File).to receive(:exist?).with('.database_consistency.todo.yml').and_return(true)
        allow(File).to receive(:exist?).with('.database_consistency.todo1.yml').and_return(false)
      end

      let(:reports) { [build_report(status: :fail)] }

      it 'writes to an incremented file name' do
        write
        expect(File).to have_received(:write).with('.database_consistency.todo1.yml', anything)
      end
    end
  end

  describe '#generate_file_name' do
    subject(:writer) { described_class.new([], config: config) }

    it 'generates the default file name without a number' do
      expect(writer.send(:generate_file_name)).to eq('.database_consistency.todo.yml')
    end

    it 'generates a numbered file name when given a number' do
      expect(writer.send(:generate_file_name, 1)).to eq('.database_consistency.todo1.yml')
    end
  end
end
