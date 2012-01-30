require 'rspec'
require 'sequel'
require './lib/sequel-hstore'

db = Sequel.connect(ENV["TEST_URL"])

require 'logger'
#db.logger = Logger.new($stdout)

db.create_table! :hstore_tests do
  column :hstore, :hstore
end

describe "hstores in the database" do
  before do
    db[:hstore_tests].delete
    @h = {:a => "b", :foo => "bar"}.to_hstore
  end

  it "should be able to store an hstore" do
    db[:hstore_tests].insert(@h)
  end

  it "should be able to round-trip an hstore" do
    db[:hstore_tests].insert(@h)
    db[:hstore_tests].first[:hstore].should == @h
  end

  it "should be able to round-trip an hstore with backslashes" do
    h = @h.merge(:slasher => 'oh \$ hell')
    db[:hstore_tests].insert(h)
    db[:hstore_tests].first[:hstore].should == h
  end
end

describe "hstores from hashes" do
  before do
    @h = {:a => "b", :foo => "bar"}.to_hstore
  end

  it "should be an HStore type" do
    @h.class.should == Sequel::Postgres::HStore
  end

  # blech
  it "class should not === Hash (for case statements)" do
    (@h.class === Hash).should == false
  end

  it "should translate into a sequel literal" do
    db[:hstore_tests].literal(@h).should == '\'"a" => "b", "foo" => "bar"\''
  end
end

describe "creating hstores from strings" do
  before do
    @h = Sequel::Postgres::HStore.new_from_string(
      "\"ip\"=>\"17.34.44.22\", \"service_available?\"=>\"false\"")
  end

  it "should be an hstore" do
    @h.is_a?(Sequel::Postgres::HStore).should == true
  end

  it "should set a value correctly" do
    @h[:service_available?].should == "false"
  end

  it "should store an empty string" do
    empty = {:nothing => ""}.to_hstore
    db[:hstore_tests].literal(empty).should == '\'"nothing" => ""\''
  end

  it "should support single quotes in strings" do
    empty = {:journey => "don't stop believin'"}.to_hstore
    db[:hstore_tests].literal(empty).should == %q{'"journey" => "don''t stop believin''"'}
  end

  it "should support double quotes in strings" do
    empty = {:journey => 'He said he was "ready"'}.to_hstore
    db[:hstore_tests].literal(empty).should == %q{'"journey" => "He said he was \"ready\""'}
  end

  it "should escape \ garbage in strings" do
    empty = {:line_noise => %q[perl -p -e 's/\$\{([^}]+)\}/]}.to_hstore
    db[:hstore_tests].literal(empty).should == %q['"line_noise" => "perl -p -e ''s/\\\\$\\\\{([^}]+)\\\\}/"']
  end

  it "should parse an empty string" do
    empty = Sequel::Postgres::HStore.new_from_string(
      "\"ip\"=>\"\", \"service_available?\"=>\"false\"")

    empty[:ip].should == ""
    empty[:ip].should_not == nil
  end

  it "should be able to parse its own output" do
    hstore = {:journey => 'He said he was ready'}.to_hstore
    literal = db[:hstore_tests].literal(hstore)
    parsed = Sequel::Postgres::HStore.new_from_string(literal)
    parsed.should == hstore
  end

  it "should be able to parse hstore strings without ''" do
    hstore = {:journey => 'He said he was ready'}.to_hstore
    literal = db[:hstore_tests].literal(hstore)
    parsed = Sequel::Postgres::HStore.new_from_string(literal[1..-2])
    parsed.should == hstore
  end

  it "should be stable over iteration" do
    hstore = {:journey => 'He said he was "ready"'}.to_hstore
    literal = db[:hstore_tests].literal(hstore)

    original = literal

    10.times do
      parsed = Sequel::Postgres::HStore.new_from_string(literal)
      literal = db[:hstore_tests].literal(parsed)
      parsed.should == hstore
      literal.should == original
    end
  end
end

