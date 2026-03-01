# frozen_string_literal: true

require 'tempfile'

if defined?(Prism)
  RSpec.describe DatabaseConsistency::PrismHelper, :sqlite, :mysql, :postgresql do
    describe DatabaseConsistency::Checkers::MissingIndexFindByChecker::FindByCollector do
      def collect(source)
        Tempfile.create(['model', '.rb']) do |f|
          f.write(source)
          f.flush
          collector = described_class.new(f.path)
          collector.visit(Prism.parse_file(f.path).value)
          return collector.results.transform_values { |locs| locs.map { |loc| loc.rpartition(':').last.to_i } }
        end
      end

      it 'detects dynamic finder' do
        expect(collect('Entity.find_by_email(x)')).to include(%w[Entity email] => [1])
      end

      it 'detects bang dynamic finder' do
        expect(collect('Entity.find_by_email!(x)')).to include(%w[Entity email] => [1])
      end

      it 'detects hash-style with symbol key' do
        expect(collect('Entity.find_by(email: x)')).to include(%w[Entity email] => [1])
      end

      it 'detects hash-style with string key' do
        expect(collect("Entity.find_by('email' => x)")).to include(%w[Entity email] => [1])
      end

      it 'detects bare find_by inside class using lexical scope' do
        expect(collect("class Entity\nfind_by(email: x)\nend")).to include(%w[Entity email] => [2])
      end

      it 'ignores bare find_by at top level (no class scope)' do
        expect(collect('find_by(email: x)')).to be_empty
      end

      it 'detects unscoped receiver' do
        expect(collect('Entity.unscoped.find_by(email: x)')).to include(%w[Entity email] => [1])
      end

      it 'detects includes receiver' do
        expect(collect('Entity.includes(:posts).find_by(email: x)')).to include(%w[Entity email] => [1])
      end

      it 'ignores multi-key hash' do
        expect(collect('Entity.find_by(email: x, name: y)')).not_to include(%w[Entity email] => [1])
      end

      it 'stores other model under its own key' do
        results = collect('OtherModel.find_by_email(x)')
        expect(results).to include(%w[OtherModel email] => [1])
      end

      it 'skips complex scope (where receiver)' do
        expect(collect('Entity.where(active: true).find_by(email: x)')).to be_empty
      end
    end
  end
end
