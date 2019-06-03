require 'readline'
require 'json'
require 'yaml'
require 'colorize'

DATA = {
  "users" => JSON.parse(File.read('data/users.json')),
  "tickets" => JSON.parse(File.read('data/tickets.json')),
  "organizations" => JSON.parse(File.read('data/organizations.json'))
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
  search(dataset, field, JSON.load("[" + value + "]").first)
end

def main
  puts 'Seach like `users.name="foo"`'.yellow

  while line = Readline.readline('search> '.green, true)
    break if line == 'exit'
    puts YAML.dump(search_with_input(line))
  end

  puts 'Goodbye'.yellow
end

main
