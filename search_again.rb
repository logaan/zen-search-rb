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

    def tick(file)
      if valid?(file)
        Results::Silent.new(Field.new(@data, file))
      else
        Results::WithOutput.new(File.new(@data), "File not found.")
      end
    end

    private

    def valid?(file)
      @data.keys.include?(file)
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

    def tick(field)
      if valid?(field)
        Results::Silent.new(Value.new(@data, @file, field))
      else
        Results::WithOutput.new(Field.new(@data, @file), "Field not found.")
      end
    end

    private

    def valid?(field)
      @data[@file].first.keys.include?(field)
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

    def tick(value)
      results = search(@file, @field, value)
      unless results.empty?
        Results::WithOutput.new(File.new(@data), YAML.dump(results))
      else
        Results::WithOutput.new(File.new(@data), "No results found.")
      end
    end

    private

    def search(file, field, value)
      parsed_value = JSON.parse(value, quirks_mode: true)
      @data[file].find_all { |row| row[field] == parsed_value }
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
  end

  def run
    state = States::File.new(@data)

    while true
      puts state.prompt.green
      input = gets.strip
      break if input == "exit"
      result = state.tick(input)
      puts result.output.yellow if result.output
      state = result.state
    end
  end

  private

  def parse_dataset(name)
    JSON.parse(File.read(File.join('data', name)))
  end
end


Runner.new().run
