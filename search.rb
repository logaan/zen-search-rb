require 'readline'
require 'json'
require 'yaml'
require 'colorize'

def parse_dataset(name)
  JSON.parse(File.read(File.join('data', name)))
end

DATA = {
  "users" => parse_dataset('users.json')
  "tickets" => parse_dataset('tickets.json')
  "organizations" => parse_dataset('organizations.json')
}

FIELDS = DATA.flat_map do |dataset, rows|
  rows.first.keys.map do |field|
    "#{dataset}.#{field}"
  end
end

Readline.completion_append_character = '='
Readline.completion_proc = proc do |string_so_far|
  FIELDS.grep(/^#{Regexp.escape(string_so_far)}/)
end

def search(dataset, field, value)
  DATA[dataset].find_all { |row| row[field] == value }
end

def search_with_input(line)
  dataset, field, value = line.split(/[\.\=]/)
  search(dataset, field, JSON.parse(value, quirks_mode: true))
end

def main
  puts 'Seach like `users.name="Francisca Rasmussen"`'.yellow

  while line = Readline.readline('search> '.green, true)
    break if line == 'exit'
    puts YAML.dump(search_with_input(line))
  end

  puts 'Goodbye'.yellow
end

main
