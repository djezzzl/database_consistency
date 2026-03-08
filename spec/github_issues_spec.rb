# frozen_string_literal: true

require 'database_consistency/github_issues'

RSpec.describe DatabaseConsistency::GithubIssues, :sqlite, :mysql, :postgresql do
  let(:checker_dir) { File.join(__dir__, '..', 'lib', 'database_consistency', 'checkers') }
  let(:autofixable_slugs) do
    DatabaseConsistency::Writers::AutofixWriter::SLUG_TO_GENERATOR.keys.map(&:to_s)
  end

  describe '.checkers_missing_autofix' do
    subject(:result) { described_class.checkers_missing_autofix(checker_dir) }

    it 'returns a non-empty hash' do
      expect(result).not_to be_empty
    end

    it 'only includes checkers that have at least one slug without an autofixer' do
      result.each_value do |slugs|
        expect(slugs.any? { |s| !autofixable_slugs.include?(s) }).to be(true)
      end
    end

    it 'does not include base or abstract checker classes' do
      expect(result.keys).not_to include('BaseChecker', 'AssociationChecker', 'ColumnChecker',
                                         'EnumChecker', 'IndexChecker', 'ModelChecker',
                                         'ValidatorChecker', 'ValidatorsFractionChecker')
    end

    it 'does not include checkers that have all slugs covered by autofixers' do
      expect(result.keys).not_to include('ForeignKeyChecker', 'ForeignKeyTypeChecker',
                                         'MissingIndexChecker', 'PrimaryKeyTypeChecker',
                                         'ThreeStateBooleanChecker', 'RedundantIndexChecker',
                                         'RedundantUniqueIndexChecker', 'MissingUniqueIndexChecker')
    end

    it 'includes checkers known to be missing autofixers' do
      expected_checkers = %w[
        ForeignKeyCascadeChecker
        MissingAssociationClassChecker
        MissingDependentDestroyChecker
        EnumValueChecker
        ImplicitOrderingChecker
        LengthConstraintChecker
        MissingIndexFindByChecker
        NullConstraintChecker
        EnumTypeChecker
        UniqueIndexChecker
        MissingTableChecker
        ViewPrimaryKeyChecker
        CaseSensitiveUniqueValidationChecker
        ColumnPresenceChecker
      ]

      expect(result.keys).to include(*expected_checkers)
    end

    it 'lists the correct missing slugs for each checker' do
      expect(result['ForeignKeyCascadeChecker']).to contain_exactly('missing_foreign_key_cascade')
      expect(result['ImplicitOrderingChecker']).to contain_exactly('implicit_order_column_missing')
      expect(result['UniqueIndexChecker']).to contain_exactly('missing_uniqueness_validation')
      expect(result['MissingTableChecker']).to contain_exactly('missing_table')
      expect(result['ColumnPresenceChecker']).to contain_exactly('possible_null')
      expect(result['NullConstraintChecker']).to contain_exactly('null_constraint_association_misses_validator',
                                                                  'null_constraint_misses_validator')
    end
  end
end
