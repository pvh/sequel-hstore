require 'strscan'

class Sequel::Postgres::HStore < Hash
  def self.quoted_string(scanner)
    key = scanner.scan(/(\\"|[^"])*/).gsub("\\\\", "\\")
    scanner.skip(/"/)
    key
  end
  def self.parse_quotable_string(scanner)
    if scanner.scan(/"/)
      value = quoted_string(scanner)
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
      k = parse_quotable_string(scanner)
      skip_key_value_delimiter(scanner)
      v = parse_quotable_string(scanner)
      skip_pair_delimiter(scanner)
      # controversial...
      # to_sym, or what?
      hash[k.to_sym] = v
    end
    self[hash]
  end

  def initialize(hash)
    @hash = hash
  end

  def to_s_escaped(str)
    str.to_s.gsub(/\\/) {'\\\\'}.gsub(/"/, '\"').gsub(/'/, "''")
  end

  def sql_literal(dataset)
    string = self.map do |(k,v)|
      if v.nil?
        # represent nil as NULL without quotes
        v = "NULL"
      else
        # otherwise, write a double-quoted string with backslash escapes for quotes
        v = to_s_escaped(v)
        v = "\"#{v}\""
      end

      # TODO: throw an error if there is a NULL key
      "\"#{to_s_escaped(k)}\" => #{v}"
    end.join(", ")
    "'#{string}'"
  end
end

