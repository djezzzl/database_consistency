# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::AutofixWriter, :sqlite, :mysql, :postgresql do
  let(:config) { DatabaseConsistency::Configuration.new }

  def build_report(status:, error_slug:)
    double('report', status: status, error_slug: error_slug)
  end

  describe '#write' do
    subject(:write) { described_class.write(reports, config: config) }

    context 'when there are no reports' do
      let(:reports) { [] }

      it 'does nothing' do
        expect { write }.not_to raise_error
      end
    end

    context 'when report status is ok' do
      let(:reports) { [build_report(status: :ok, error_slug: :null_constraint_missing)] }

      it 'does not call fix!' do
        expect_any_instance_of(DatabaseConsistency::Writers::Autofix::NullConstraintMissing).not_to receive(:fix!)
        write
      end
    end

    context 'when report status is fail' do
      let(:report) { build_report(status: :fail, error_slug: :null_constraint_missing) }
      let(:reports) { [report] }

      before do
        allow(report).to receive(:table_name).and_return('users')
        allow(report).to receive(:column_name).and_return('email')
      end

      it 'calls fix! on the generator' do
        expect_any_instance_of(DatabaseConsistency::Writers::Autofix::NullConstraintMissing).to receive(:fix!)
        write
      end
    end

    context 'when error_slug has no generator' do
      let(:reports) { [build_report(status: :fail, error_slug: :unknown_slug)] }

      it 'does not raise' do
        expect { write }.not_to raise_error
      end
    end

    context 'when there are duplicate generators' do
      let(:report1) { build_report(status: :fail, error_slug: :null_constraint_missing) }
      let(:report2) { build_report(status: :fail, error_slug: :null_constraint_missing) }
      let(:reports) { [report1, report2] }

      before do
        [report1, report2].each do |r|
          allow(r).to receive(:table_name).and_return('users')
          allow(r).to receive(:column_name).and_return('email')
        end
      end

      it 'calls fix! only once for duplicates' do
        expect_any_instance_of(DatabaseConsistency::Writers::Autofix::NullConstraintMissing)
          .to receive(:fix!).once
        write
      end
    end

    context 'when there are different generators' do
      let(:null_report) { build_report(status: :fail, error_slug: :null_constraint_missing) }
      let(:index_report) { build_report(status: :fail, error_slug: :redundant_index) }
      let(:reports) { [null_report, index_report] }

      before do
        allow(null_report).to receive(:table_name).and_return('users')
        allow(null_report).to receive(:column_name).and_return('email')
        allow(index_report).to receive(:index_name).and_return('index_users_on_email')
        allow(index_report).to receive(:table_name).and_return('users')
      end

      it 'calls fix! on each unique generator' do
        expect_any_instance_of(DatabaseConsistency::Writers::Autofix::NullConstraintMissing)
          .to receive(:fix!).once
        expect_any_instance_of(DatabaseConsistency::Writers::Autofix::RedundantIndex)
          .to receive(:fix!).once
        write
      end
    end
  end

  describe 'SLUG_TO_GENERATOR' do
    subject(:slug_map) { described_class::SLUG_TO_GENERATOR }

    it 'maps association_missing_index to AssociationMissingIndex' do
      expect(slug_map[:association_missing_index]).to eq(DatabaseConsistency::Writers::Autofix::AssociationMissingIndex)
    end

    it 'maps association_missing_null_constraint to NullConstraintMissing' do
      expect(slug_map[:association_missing_null_constraint])
        .to eq(DatabaseConsistency::Writers::Autofix::NullConstraintMissing)
    end

    it 'maps has_one_missing_unique_index to HasOneMissingUniqueIndex' do
      expect(slug_map[:has_one_missing_unique_index])
        .to eq(DatabaseConsistency::Writers::Autofix::HasOneMissingUniqueIndex)
    end

    it 'maps inconsistent_types to InconsistentTypes' do
      expect(slug_map[:inconsistent_types]).to eq(DatabaseConsistency::Writers::Autofix::InconsistentTypes)
    end

    it 'maps missing_foreign_key to MissingForeignKey' do
      expect(slug_map[:missing_foreign_key]).to eq(DatabaseConsistency::Writers::Autofix::MissingForeignKey)
    end

    it 'maps missing_unique_index to HasOneMissingUniqueIndex' do
      expect(slug_map[:missing_unique_index]).to eq(DatabaseConsistency::Writers::Autofix::HasOneMissingUniqueIndex)
    end

    it 'maps null_constraint_missing to NullConstraintMissing' do
      expect(slug_map[:null_constraint_missing]).to eq(DatabaseConsistency::Writers::Autofix::NullConstraintMissing)
    end

    it 'maps redundant_index to RedundantIndex' do
      expect(slug_map[:redundant_index]).to eq(DatabaseConsistency::Writers::Autofix::RedundantIndex)
    end

    it 'maps redundant_unique_index to RedundantIndex' do
      expect(slug_map[:redundant_unique_index]).to eq(DatabaseConsistency::Writers::Autofix::RedundantIndex)
    end

    it 'maps small_primary_key to InconsistentTypes' do
      expect(slug_map[:small_primary_key]).to eq(DatabaseConsistency::Writers::Autofix::InconsistentTypes)
    end

    it 'maps three_state_boolean to NullConstraintMissing' do
      expect(slug_map[:three_state_boolean]).to eq(DatabaseConsistency::Writers::Autofix::NullConstraintMissing)
    end
  end
end
