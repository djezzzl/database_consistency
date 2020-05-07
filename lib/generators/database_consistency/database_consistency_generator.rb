# frozen_string_literal: true

# Basic generator to copy usefull defaults for Rails apps
class DatabaseConsistencyGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  desc 'Create a DatabaseConsistency for Rails'
  def install
    template '.database_consistency.yml', '.database_consistency.yml'
  end
end
