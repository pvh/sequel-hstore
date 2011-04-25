# timing is bad

class Sequel::Postgres::HStore < Hash
  def self.new_from_string(string)
    hash = {}
    string.split(/,\s*/).each do |pair|
      (key, value) = pair.split(/\s*=>\s*/)
      # strip the quotes off
      hash[key[1..-2]] = value[1..-2]
    end
    self[hash]
  end
  def initialize(hash)
    @hash = hash
  end
  def sql_literal(dataset)
    "\'{" + self.map { |(k,v)| "#{k.to_s} => #{v.to_s}" }.join(", ") + "}\'"
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

