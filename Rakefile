# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :github do
  desc 'Create GitHub issues for checkers that are missing autofixer support'
  task :create_missing_autofix_issues do
    require_relative 'lib/database_consistency'
    require_relative 'lib/database_consistency/github_issues'

    github_token = ENV.fetch('GITHUB_TOKEN') do
      raise ArgumentError, 'Please provide a GitHub token via the GITHUB_TOKEN environment variable'
    end

    checker_dir = File.join(__dir__, 'lib', 'database_consistency', 'checkers')
    checkers = DatabaseConsistency::GithubIssues.checkers_missing_autofix(checker_dir)

    if checkers.empty?
      puts 'All checkers have autofixer support!'
      next
    end

    checkers.each do |checker_name, missing_slugs|
      DatabaseConsistency::GithubIssues.create_issue_for_checker(checker_name, missing_slugs, github_token)
    end
  end
end
