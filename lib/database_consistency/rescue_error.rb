# frozen_string_literal: true

module DatabaseConsistency
  # The class writes error to the file
  class RescueError
    private_class_method :new

    def self.call(error)
      @singleton ||= new
      @singleton.call(error)
    end

    # @return [Boolean]
    def self.empty?
      @singleton.nil?
    end

    def initialize
      puts 'Some checks failed with an error. Please open an issue on GitHub at https://github.com/djezzzl/database_consistency.'
      puts "Attach the generated file: #{filename}"
      puts 'Thank you for your contribution!'
      puts '(c) Evgeniy Demin <lawliet.djez@gmail.com>'
    end

    def call(error)
      File.open(filename, 'a') do |file|
        file.puts('<===begin===>')
        file.puts('Metadata:')
        DebugContext.output(file)
        file.puts('Stack trace:')
        file.puts(error.full_message)
        file.puts('<===end===>')
      end
    end

    private

    def filename
      @filename ||= "database_consistency_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.txt"
    end
  end
end
