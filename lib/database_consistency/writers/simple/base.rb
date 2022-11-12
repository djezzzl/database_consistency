# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class Base # :nodoc:
        COLORS = {
          blue: "\e[34m",
          yellow: "\e[33m",
          green: "\e[32m",
          red: "\e[31m"
        }.freeze

        COLOR_BY_STATUS = {
          ok: :green,
          warning: :yellow,
          fail: :red
        }.freeze

        def self.with(text)
          Class.new(self) do
            define_method :template do
              text
            end
          end
        end

        attr_reader :report, :config

        def initialize(report, config:)
          @report = report
          @config = config
        end

        def msg
          "#{report.checker_name} #{status_text} #{key_text} #{message_text}"
        end

        private

        def message_text
          template % attributes
        end

        def attributes
          {}
        end

        def key_text
          "#{colorize(report.table_or_model_name, :blue)} #{colorize(report.column_or_attribute_name, :yellow)}"
        end

        def colorize(text, color)
          return text unless config.colored? && color

          "#{COLORS[color]}#{text}\e[0m"
        end

        def status_text
          color = COLOR_BY_STATUS[report.status]

          colorize(report.status, color)
        end
      end
    end
  end
end
