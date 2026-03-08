# frozen_string_literal: true

require 'net/http'
require 'json'

module DatabaseConsistency
  # Module for creating GitHub issues for checkers missing autofixer support
  module GithubIssues
    REPO = 'djezzzl/database_consistency'

    class << self
      # Returns a hash of checker_name => [missing_slugs] for checkers that
      # have at least one error slug without a corresponding autofixer.
      def checkers_missing_autofix(checker_dir)
        autofixable = Writers::AutofixWriter::SLUG_TO_GENERATOR.keys.map(&:to_s)

        Dir.glob(File.join(checker_dir, '**', '*.rb')).each_with_object({}) do |file, result|
          content = File.read(file)
          next unless (class_match = content.match(/class (\w+Checker) </))

          checker_name = class_match[1]
          missing = content.scan(/error_slug: :(\w+)/).flatten.uniq.reject { |s| autofixable.include?(s) }
          result[checker_name] = missing unless missing.empty?
        end
      end

      # Creates a GitHub issue for the given checker with the missing slugs.
      # Skips creation if an open issue with the same title already exists.
      def create_issue_for_checker(checker_name, missing_slugs, github_token)
        title = "Add autofix support for `#{checker_name}`"

        if issue_exists?(title, github_token)
          puts "Skipping `#{checker_name}`: issue already exists."
          return
        end

        body = build_issue_body(checker_name, missing_slugs)
        url = post_issue(title, body, github_token)
        puts "Created issue for `#{checker_name}`: #{url}"
      end

      private

      def issue_exists?(title, github_token)
        query = "repo:#{REPO} is:issue in:title #{title.inspect}"
        uri = URI('https://api.github.com/search/issues')
        uri.query = URI.encode_www_form(q: query)

        response = github_request(Net::HTTP::Get, uri, github_token)
        JSON.parse(response.body)['total_count'].to_i.positive?
      end

      def post_issue(title, body, github_token)
        uri = URI("https://api.github.com/repos/#{REPO}/issues")
        payload = JSON.generate(title: title, body: body)

        response = github_request(Net::HTTP::Post, uri, github_token, payload)
        JSON.parse(response.body)['html_url']
      end

      def github_request(method_class, uri, github_token, body = nil)
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          request = method_class.new(uri)
          request['Authorization'] = "Bearer #{github_token}"
          request['Accept'] = 'application/vnd.github+json'
          request['Content-Type'] = 'application/json' if body
          request.body = body if body
          http.request(request)
        end
      end

      def build_issue_body(checker_name, missing_slugs)
        slug_list = missing_slugs.map { |s| "- `#{s}`" }.join("\n")

        <<~BODY
          ## Summary

          `#{checker_name}` is missing autofix support for the following error slug(s):

          #{slug_list}

          ## Task

          Implement an autofixer for `#{checker_name}` that generates the appropriate migration(s) \
          to resolve the detected issues automatically.

          Please refer to the existing autofix implementations in \
          `lib/database_consistency/writers/autofix/` for guidance.
        BODY
      end
    end
  end
end
