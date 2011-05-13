# This is an awful monkey patch lifted from some other project. Can we improve on this somehow?
# (See github.com/couchrest/couchrest-core(?))
require 'sequel/adapters/postgres'
require_relative 'hstore/hstore'

class Hash
  def to_hstore
    Sequel::Postgres::HStore[self.dup]
  end

  def self.===(other)
    return false if self == Hash && other.is_a?(Sequel::Postgres::HStore)
    super
  end
end

Sequel::Postgres::PG_NAMED_TYPES[:hstore] = lambda{|s| Sequel::Postgres::HStore.new_from_string(s) }

