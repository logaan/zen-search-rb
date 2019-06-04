require 'readline'
require 'json'
require 'yaml'
require 'colorize'

module States
  class File
    def initialize(data)
      @data = data
    end

    def prompt
      'Which file would you like to search?'
    end

    def options
      @data.keys.sort
    end

    def tick(file)
      if valid?(file)
        Results::Silent.new(Field.new(@data, file))
      else
        Results::WithOutput.new(self, "File not found.")
      end
    end

    private

    def valid?(file)
      options.include?(file)
    end
  end

  class Field
    def initialize(data, file)
      @data = data
      @file = file
    end

    def prompt
      'Which field should we look in?'
    end

    def options
      @data[@file].first.keys.sort
    end

    def tick(field)
      if valid?(field)
        Results::Silent.new(Value.new(@data, @file, field))
      else
        Results::WithOutput.new(self, "Field not found.")
      end
    end

    private

    def valid?(field)
      options.include?(field)
    end
  end

  class Value
    def initialize(data, file, field)
      @data = data
      @file = file
      @field = field
    end

    def prompt
      "What's the value you'd like?"
    end

    def options
      @data[@file].map{ |row| row[@field].to_json }.uniq.sort
    end

    def tick(value)
      results = search(value)

      unless results.empty?
        Results::WithOutput.new(File.new(@data), YAML.dump(results))
      else
        Results::WithOutput.new(File.new(@data), "No results found.")
      end
    rescue JSON::ParserError
      Results::WithOutput.new(self, "Please search with JSON values.")
    end

    private

    def search(value)
      parsed_value = JSON.parse(value, quirks_mode: true)
      @data[@file].find_all { |row| row[@field] == parsed_value }
    end
  end
end

module Results
  class Silent
    attr_reader :state, :output

    def initialize(state)
      @state = state
    end
  end

  class WithOutput
    attr_reader :state, :output

    def initialize(state, output)
      @state = state
      @output = output
    end
  end
end

class Runner
  def initialize()
    @data = {
      "users" => parse_dataset('users.json'),
      "tickets" => parse_dataset('tickets.json'),
      "organizations" => parse_dataset('organizations.json')
    }

    @state = States::File.new(@data)
  end

  def run
    while true
      puts @state.prompt.green
      input = get_input
      break if input.nil? or input.strip == "exit"
      result = @state.tick(input.strip)
      puts result.output.yellow if result.output
      @state = result.state
    end
  end

  private

  def parse_dataset(name)
    JSON.parse(File.read(File.join('data', name)))
  end

  def get_input
    Readline.completion_proc = proc do |string_so_far|
      @state.options.grep(/^#{Regexp.escape(string_so_far)}/)
    end

    Readline.readline('> '.green, true)
  end
end

Runner.new().run
