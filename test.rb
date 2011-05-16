require 'sequel'
require './lib/sequel-hstore'
db = Sequel.connect(ENV["TEST_URL"])

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
    db[:resources].literal(@h).should == '\'"a" => "b", "foo" => "bar"\''
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
    db[:resources].literal(empty).should == '\'"nothing" => ""\''
  end

  it "should parse an empty string" do
    empty = Sequel::Postgres::HStore.new_from_string(
      "\"ip\"=>\"\", \"service_available?\"=>\"false\"")

    empty[:ip].should == ""
    empty[:ip].should_not == nil
  end
end

