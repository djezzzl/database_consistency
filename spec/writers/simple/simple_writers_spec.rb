# frozen_string_literal: true

RSpec.describe 'Simple writers', :sqlite, :mysql, :postgresql do # rubocop:disable RSpec/DescribeClass
  let(:config) { DatabaseConsistency::Configuration.new }

  def build_writer(klass, report)
    klass.new(report, config: config)
  end

  def report_double(attrs = {})
    defaults = {
      checker_name: 'TestChecker',
      status: :fail,
      table_or_model_name: 'users',
      column_or_attribute_name: 'email',
      error_message: nil
    }
    double('report', defaults.merge(attrs))
  end

  describe DatabaseConsistency::Writers::Simple::AssociationForeignTypeMissingNullConstraint do
    let(:report) { report_double(table_name: 'users', column_name: 'user_type') }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template' do
      expect(writer.send(:template)).to include('NOT NULL')
    end

    it 'returns unique_attributes with table_name and column_name' do
      expect(writer.unique_key).to include(table_name: 'users', column_name: 'user_type')
    end
  end

  describe DatabaseConsistency::Writers::Simple::AssociationMissingIndex do
    let(:report) { report_double(table_name: 'posts', columns: ['user_id']) }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template' do
      expect(writer.send(:template)).to include('index')
    end

    it 'returns unique_attributes with table_name and columns' do
      expect(writer.unique_key).to include(table_name: 'posts', columns: ['user_id'])
    end
  end

  describe DatabaseConsistency::Writers::Simple::AssociationMissingNullConstraint do
    let(:report) { report_double(table_name: 'users', column_name: 'company_id') }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template' do
      expect(writer.send(:template)).to include('NOT NULL')
    end

    it 'returns unique_attributes with table_name and column_name' do
      expect(writer.unique_key).to include(table_name: 'users', column_name: 'company_id')
    end
  end

  describe DatabaseConsistency::Writers::Simple::DefaultMessage do
    let(:report) { report_double(error_message: 'custom error', to_h: { custom: 'val' }) }
    subject(:writer) { build_writer(described_class, report) }

    it 'uses error_message as template' do
      expect(writer.send(:template)).to eq('custom error')
    end

    it 'uses report.to_h for unique_attributes' do
      expect(writer.unique_key).to include(custom: 'val')
    end
  end

  describe DatabaseConsistency::Writers::Simple::EnumValuesInconsistentWithArEnum do
    let(:report) do
      report_double(enum_values: %w[a b], declared_values: %w[c d])
    end
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template mentioning ActiveRecord enum' do
      expect(writer.send(:template)).to include('ActiveRecord enum')
    end

    it 'formats enum_values and declared_values in the message' do
      expect(writer.msg).to include('a, b')
      expect(writer.msg).to include('c, d')
    end

    it 'returns unique_attributes with ar_enum flag' do
      expect(writer.unique_key).to include(ar_enum: true)
    end
  end

  describe DatabaseConsistency::Writers::Simple::EnumValuesInconsistentWithInclusion do
    let(:report) do
      report_double(enum_values: %w[x y], declared_values: %w[z w])
    end
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template mentioning inclusion validation' do
      expect(writer.send(:template)).to include('inclusion validation')
    end

    it 'formats enum_values and declared_values in the message' do
      expect(writer.msg).to include('x, y')
      expect(writer.msg).to include('z, w')
    end

    it 'returns unique_attributes with inclusion flag' do
      expect(writer.unique_key).to include(inclusion: true)
    end
  end

  describe DatabaseConsistency::Writers::Simple::HasOneMissingUniqueIndex do
    let(:report) { report_double(table_name: 'users', columns: ['email']) }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template' do
      expect(writer.send(:template)).to include('unique index')
    end

    it 'returns unique_attributes with unique: true' do
      expect(writer.unique_key).to include(unique: true)
    end
  end

  describe DatabaseConsistency::Writers::Simple::ImplicitOrderColumnMissing do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning implicit_order_column' do
      expect(writer.send(:template)).to include('implicit_order_column')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::InconsistentEnumType do
    let(:report) do
      report_double(values_types: %w[string integer], column_type: 'integer')
    end
    subject(:writer) { build_writer(described_class, report) }

    it 'includes values_types and column_type in message' do
      expect(writer.msg).to include('string, integer')
      expect(writer.msg).to include('integer')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::InconsistentTypes do
    let(:report) do
      report_double(
        fk_name: 'user_id', fk_type: 'integer',
        pk_name: 'id', pk_type: 'bigint',
        table_to_change: 'posts', type_to_set: 'bigint'
      )
    end
    subject(:writer) { build_writer(described_class, report) }

    it 'includes fk/pk names and types in message' do
      expect(writer.msg).to include('user_id')
      expect(writer.msg).to include('integer')
      expect(writer.msg).to include('bigint')
    end

    it 'returns unique_attributes with table_to_change and fk_name' do
      expect(writer.unique_key).to include(table_to_change: 'posts', fk_name: 'user_id')
    end
  end

  describe DatabaseConsistency::Writers::Simple::LengthValidatorGreaterLimit do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning length validator' do
      expect(writer.send(:template)).to include('length validator')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::LengthValidatorLowerLimit do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning length validator' do
      expect(writer.send(:template)).to include('length validator')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::LengthValidatorMissing do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning length validator' do
      expect(writer.send(:template)).to include('length validator')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingAssociationClass do
    let(:report) { report_double(class_name: 'Profile') }
    subject(:writer) { build_writer(described_class, report) }

    it 'includes class_name in message' do
      expect(writer.msg).to include('Profile')
    end

    it 'returns unique_attributes with class_name' do
      expect(writer.unique_key).to include(class_name: 'Profile')
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingDependentDestroy do
    let(:report) { report_double(model_name: 'Company', attribute_name: 'users') }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template mentioning dependent' do
      expect(writer.send(:template)).to include('dependent')
    end

    it 'returns unique_attributes with model_name and attribute_name' do
      expect(writer.unique_key).to include(model_name: 'Company', attribute_name: 'users')
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingForeignKey do
    let(:report) do
      report_double(
        foreign_table: 'posts', foreign_key: 'user_id',
        primary_table: 'users', primary_key: 'id'
      )
    end
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template mentioning foreign key' do
      expect(writer.send(:template)).to include('foreign key')
    end

    it 'returns unique_attributes with foreign and primary table info' do
      expect(writer.unique_key).to include(
        foreign_table: 'posts', foreign_key: 'user_id',
        primary_table: 'users', primary_key: 'id'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingForeignKeyCascade do
    let(:report) do
      report_double(
        cascade_option: 'delete',
        foreign_table: 'posts', foreign_key: 'user_id',
        primary_table: 'users', primary_key: 'id'
      )
    end
    subject(:writer) { build_writer(described_class, report) }

    it 'includes cascade_option in message' do
      expect(writer.msg).to include('delete')
    end

    it 'returns unique_attributes with cascade_option and foreign/primary table info' do
      expect(writer.unique_key).to include(
        cascade_option: 'delete',
        foreign_table: 'posts',
        foreign_key: 'user_id'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingIndexFindBy do
    context 'without source_location' do
      let(:report) { report_double(source_location: nil, total_findings_count: nil) }
      subject(:writer) { build_writer(described_class, report) }

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
      let(:report) { report_double(source_location: 'app/models/user.rb:10', total_findings_count: 1) }
      subject(:writer) { build_writer(described_class, report) }

      it 'includes source_location in message' do
        expect(writer.msg).to include('app/models/user.rb:10')
      end
    end

    context 'with multiple findings' do
      let(:report) { report_double(source_location: 'app/models/user.rb:10', total_findings_count: 3) }
      subject(:writer) { build_writer(described_class, report) }

      it 'mentions additional findings count' do
        expect(writer.msg).to include('and 2 more')
      end
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingTable do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning table' do
      expect(writer.send(:template)).to include('table')
    end

    it 'returns unique_attributes with table_or_model_name' do
      expect(writer.unique_key).to include(table_or_model_name: 'users')
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingUniqueIndex do
    let(:report) { report_double(table_name: 'users', columns: ['email']) }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template mentioning unique index' do
      expect(writer.send(:template)).to include('unique index')
    end

    it 'returns unique_attributes with unique: true' do
      expect(writer.unique_key).to include(unique: true)
    end
  end

  describe DatabaseConsistency::Writers::Simple::MissingUniquenessValidation do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning uniqueness validator' do
      expect(writer.send(:template)).to include('uniqueness validator')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::NullConstraintAssociationMissesValidator do
    let(:report) { report_double(association_name: 'company') }
    subject(:writer) { build_writer(described_class, report) }

    it 'includes association_name in message' do
      expect(writer.msg).to include('company')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::NullConstraintMissesValidator do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning NOT NULL' do
      expect(writer.send(:template)).to include('NOT NULL')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::NullConstraintMissing do
    let(:report) { report_double(table_name: 'users', column_name: 'email') }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template mentioning NOT NULL' do
      expect(writer.send(:template)).to include('NOT NULL')
    end

    it 'returns unique_attributes with table_name and column_name' do
      expect(writer.unique_key).to include(table_name: 'users', column_name: 'email')
    end
  end

  describe DatabaseConsistency::Writers::Simple::PossibleNull do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning NULL' do
      expect(writer.send(:template)).to include('NULL')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::RedundantCaseInsensitiveOption do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning case_sensitive' do
      expect(writer.send(:template)).to include('case_sensitive')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::RedundantIndex do
    let(:report) { report_double(covered_index_name: 'index_users_on_email_and_name', index_name: 'index_users_on_email') }
    subject(:writer) { build_writer(described_class, report) }

    it 'includes covered_index_name in message' do
      expect(writer.msg).to include('index_users_on_email_and_name')
    end

    it 'returns unique_attributes with index_name' do
      expect(writer.unique_key).to include(index_name: 'index_users_on_email')
    end
  end

  describe DatabaseConsistency::Writers::Simple::RedundantUniqueIndex do
    let(:report) { report_double(covered_index_name: 'index_users_on_email_and_name', index_name: 'index_users_on_email') }
    subject(:writer) { build_writer(described_class, report) }

    it 'includes covered_index_name in message' do
      expect(writer.msg).to include('index_users_on_email_and_name')
    end

    it 'returns unique_attributes with index_name' do
      expect(writer.unique_key).to include(index_name: 'index_users_on_email')
    end
  end

  describe DatabaseConsistency::Writers::Simple::SmallPrimaryKey do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning bigint/bigserial' do
      expect(writer.send(:template)).to include('bigint')
    end

    it 'returns unique_attributes with table_or_model_name and column_or_attribute_name' do
      expect(writer.unique_key).to include(
        table_or_model_name: 'users',
        column_or_attribute_name: 'email'
      )
    end
  end

  describe DatabaseConsistency::Writers::Simple::ThreeStateBoolean do
    let(:report) { report_double(table_name: 'users', column_name: 'active') }
    subject(:writer) { build_writer(described_class, report) }

    it 'has a template mentioning NOT NULL' do
      expect(writer.send(:template)).to include('NOT NULL')
    end

    it 'returns unique_attributes with table_name and column_name' do
      expect(writer.unique_key).to include(table_name: 'users', column_name: 'active')
    end
  end

  describe DatabaseConsistency::Writers::Simple::ViewMissingPrimaryKey do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning primary_key' do
      expect(writer.send(:template)).to include('primary_key')
    end

    it 'returns unique_attributes with table_or_model_name' do
      expect(writer.unique_key).to include(table_or_model_name: 'users')
    end
  end

  describe DatabaseConsistency::Writers::Simple::ViewPrimaryKeyColumnMissing do
    subject(:writer) { build_writer(described_class, report_double) }

    it 'has a template mentioning primary_key' do
      expect(writer.send(:template)).to include('primary_key')
    end

    it 'returns unique_attributes with table_or_model_name' do
      expect(writer.unique_key).to include(table_or_model_name: 'users')
    end
  end
end
