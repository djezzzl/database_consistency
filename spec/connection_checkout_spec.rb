# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors, :sqlite, :mysql, :postgresql do
  # `ActiveRecord.permanent_connection_checkout` was added in ActiveRecord 7.2. With `:disallowed`, an implicit
  #   permanent checkout through `Model.connection` raises, so every check must use a scoped connection instead.
  #   Older versions have no such setting and keep using `Model.connection`, which the rest of the suite covers.
  if ActiveRecord.respond_to?(:permanent_connection_checkout=)
    context 'when permanent connection checkout is disallowed' do
      subject(:reports) { described_class.reports(DatabaseConsistency::Configuration.new) }

      before do
        allow(DatabaseConsistency::Helper).to receive(:project_klass?).and_return(true)

        define_database_with_entity { |table| table.string :email }
        define_class('Entity', :entities) { |klass| klass.validates :email, presence: true }

        allow(ActiveRecord::Base).to receive(:descendants).and_return([Entity])

        @previous_checkout = ActiveRecord.permanent_connection_checkout
        ActiveRecord::Base.release_connection
        ActiveRecord.permanent_connection_checkout = :disallowed
      end

      after { ActiveRecord.permanent_connection_checkout = @previous_checkout }

      it 'runs the checks and still reports inconsistencies' do
        expect(DatabaseConsistency::RescueError).not_to receive(:call)

        expect(reports).to include(
          have_attributes(
            checker_name: 'ColumnPresenceChecker',
            table_or_model_name: 'Entity',
            column_or_attribute_name: 'email',
            status: :fail
          )
        )
      end
    end
  end
end
