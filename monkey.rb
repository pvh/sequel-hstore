# timing is bad
require 'strscan'

class Sequel::Postgres::HStore < Hash
  def self.parse_quotable_string(scanner)
    if scanner.scan(/"/)
      key = scanner.scan(/(\\"|[^"])+/).gsub("\\", "")
      scanner.skip(/"/)
      key
    else
      value = scanner.scan(/\w+/)
      value = nil if value == "NULL"
      # TODO: values but not keys may be NULL
    end
  end

  def self.skip_key_value_delimiter(scanner)
    scanner.skip(/\s*=>\s*/) 
  end

  def self.skip_pair_delimiter(scanner)
    scanner.skip(/,\s*/)
  end

  def self.new_from_string(string)
    hash = {}
    scanner = StringScanner.new(string)
    while !scanner.eos?
      key = parse_quotable_string(scanner)
      skip_key_value_delimiter(scanner)
      value = parse_quotable_string(scanner)
      skip_pair_delimiter(scanner)

      hash[key] = value
    end

    self[hash]
  end
  def initialize(hash)
    @hash = hash
  end

  def sql_literal(dataset)
    string = self.map do |(k,v)|
      if v.nil?
        # represent nil as NULL without quotes
        v = "NULL"
      else
        # otherwise, write a double-quoted string with backslash escapes for quotes
        v = v.to_s.gsub('"', '\"')
        v = "\"#{v}\""
      end
      # TODO: throw an error if there is a NULL key
      "\"#{k.to_s}\" => #{v}"
    end.join(", ")
    puts string
    "'#{string}'"
  end
end

class Hash
  def to_hstore
    Sequel::Postgres::HStore[self.dup]
  end

  def self.===(other)
    return false if self == Hash && other.is_a?(Sequel::Postgres::HStore)
    super
  end
end

Sequel::Postgres::PG_TYPES[16392] = lambda{|s| Sequel::Postgres::HStore.new_from_string(s) }

