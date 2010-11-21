require 'spec_helper'
  
shared_examples_for "primer cache" do
  before do
    Primer.cache = cache
    cache.bind_to_bus
    
    @person   = Person.create(:name => "Abe")
    @impostor = Person.create(:name => "Aaron")
    @post     = BlogPost.create(:person => @impostor, :title => "roflmillions")
  end
  
  describe "#compute with a block" do
    def compute_value
      cache.compute("/people/abe/name") { @person.name }
    end
    
    it "returns the value of the block" do
      compute_value.should == "Abe"
    end
    
    it "calls the implementation to get the value" do
      @person.should_receive(:name)
      compute_value
    end
    
    it "stores the result of the computation" do
      cache.should_receive(:put).with("/people/abe/name", "Abe")
      compute_value
    end
    
    it "notes that the value is related to some ActiveRecord data" do
      cache.should_receive(:relate).with("/people/abe/name", [["ActiveRecord", "Person", @person.id, "name"]])
      compute_value
    end
    
    describe "when the value is already known" do
      before { compute_value }
      
      it "returns the value of the block" do
        compute_value.should == "Abe"
      end
      
      it "does not call the implementation" do
        @person.should_not_receive(:name)
        compute_value
      end
      
      it "invalidates the cache when related data changes" do
        cache.should_receive(:invalidate).with("/people/abe/name")
        @person.update_attribute(:name, "Aaron")
      end
      
      it "does not invalidate the cache when a different object changes" do
        cache.should_not_receive(:invalidate)
        @impostor.update_attribute(:name, "Weeble")
      end
      
      it "does not invalidate the cache when unrelated data changes" do
        cache.should_not_receive(:invalidate)
        @person.update_attribute(:age, 28)
      end
    end
  end
  
  describe "#compute without a block" do
    let(:compute_value)  { cache.compute("/name") }
    let(:compute_count)  { cache.compute("/count") }
    let(:compute_author) { cache.compute("/author") }
    
    before do
      cache.routes = Primer::RouteSet.new do
        get('/name')     { Person.first.name }
        get('/bar/:id') { params[:id] }
        get('/count')   { Person.first.blog_posts.count }
        get('/author')  { BlogPost.first.person.name }
      end
    end
    
    it "uses the routes to find the right value" do
      compute_value.should == "Abe"
    end
    
    it "stores the result of the computation" do
      cache.should_receive(:put).with("/name", "Abe")
      compute_value
    end
    
    it "notes that the value is related to some ActiveRecord data" do
      cache.should_receive(:relate).with("/name", [["ActiveRecord", "Person", @person.id, "name"]])
      compute_value
    end
    
    it "handles routing patterns and params" do
      cache.should_receive(:put).with("/bar/pattern_match", "pattern_match")
      cache.should_receive(:relate).with("/bar/pattern_match", [])
      cache.compute("/bar/pattern_match").should == "pattern_match"
    end
    
    it "raise an error for paths that don't match anything" do
      cache.should_not_receive(:put)
      cache.should_not_receive(:relate)
      lambda { cache.compute("/qux") }.should raise_error(Primer::RouteNotFound)
    end
    
    describe "when the value is already known" do
      before do
        compute_value
        compute_count
        compute_author
      end
      
      it "returns the value of the block" do
        compute_value.should == "Abe"
      end
      
      it "does not call the implementation" do
        @person.should_not_receive(:name)
        compute_value
      end
      
      it "regenerates the cache when related data changes" do
        @person.update_attribute(:name, "Aaron")
        cache.get("/name").should == "Aaron"
      end
      
      it "regenerates the cache when an associated collection changes" do
        BlogPost.create(:person => @person, :title => "ROFLscale")
        cache.get("/count").to_i.should == 1
      end
      
      it "regenerates the cache when an association is changed" do
        @post.update_attribute(:person, @person)
        cache.get("/author").should == "Abe"
      end
      
      it "regenerates the cache when an associated object changes" do
        @impostor.update_attribute(:name, "Steve")
        cache.get("/author").should == "Steve"
      end
    end
  end
  
  describe "nested cache values" do
    before do
      cache.routes = Primer::RouteSet.new do
        get('/title')   { BlogPost.first.title }
        get('/content') { BlogPost.first.person.name + Primer.cache.compute('/title') }
      end
    end
    
    it "returns the correct value for the outer computation" do
      cache.compute("/content").should == "Aaronroflmillions"
    end
    
    describe "when the inner cache value is known before computing the outer value" do
      before do
        cache.compute("/title")
        cache.compute("/content")
      end
      
      it "returns the correct value for the outer computation" do
        cache.compute("/content").should == "Aaronroflmillions"
      end
      
      it "updates the cache when the title changes" do
        @post.update_attribute(:title, "It's toasted")
        cache.get("/title").should == "It's toasted"
        cache.get("/content").should == "AaronIt's toasted"
      end
    end
  end
  
  describe "throttling" do
    before do
      cache.routes = Primer::RouteSet.new do
        get("/data") { [BlogPost.first.title, Person.first.name] }
      end
      cache.throttle = 0.5
      cache.compute("/data")
    end
    
    it "restricts how often the cache is recalculated" do
      cache.should_receive(:regenerate).once
      @post.update_attribute(:title, "The new title")
      @person.update_attribute(:name, "The new name")
      sleep 1.0
    end
    
    it "regenerates after the given throttle time, not after the first trigger" do
      @post.update_attribute(:title, "The new title")
      cache.get("/data").should == ["roflmillions", "Abe"]
      
      @person.update_attribute(:name, "The new name")
      cache.get("/data").should == ["roflmillions", "Abe"]
      
      sleep 1.0
      cache.get("/data").should == ["The new title", "The new name"]
    end
  end
  
  describe "#get" do
    it "can be caught by the Watcher" do
      calls = []
      Primer::Watcher.watching(calls) { cache.get("/a/key") }
      calls.should == [[cache, :get, ["/a/key"], nil, nil]]
    end
  end
  
  describe "#put" do
    before { cache.get("/key").should be_nil }
    
    it "writes a value to the cache" do
      cache.put("/key", "value")
      cache.get("/key").should == "value"
    end
    
    it "raises an error if any invalid key is used" do
      lambda { cache.put("invalid", "hmm") }.should raise_error(Primer::InvalidKey)
    end
    
    it "can store arbitrary data" do
      value = ["foo", 4, [5, :bar], {:qux => [6, 7]}]
      cache.put("/key", value)
      cache.get("/key").should == value
    end
  end
  
  describe "#invalidate" do
    before { cache.put("/some/key", "value") }
    
    it "removes the key from the cache" do
      cache.invalidate("/some/key")
      cache.get("/some/key").should be_nil
    end
    
    describe "when a cache value has been generated from a computation" do
      before { cache.compute("/people/abe/name") { @person.name } }
      
      it "removes existing relations between the model and the cache" do
        cache.invalidate("/people/abe/name")
        cache.should_not_receive(:invalidate)
        @person.update_attribute(:name, "Weeble")
      end
    end
  end
  
  describe "#clear" do
    before { cache.put("/some/key", "value") }
    
    it "empties the cache" do
      cache.clear
      cache.get("/some/key").should be_nil
    end
  end
end

describe Primer::Cache::Memory do
  let(:cache) { Primer::Cache::Memory.new }
  it_should_behave_like "primer cache"
end

describe Primer::Cache::Redis do
  let(:cache) { Primer::Cache::Redis.new }
  it_should_behave_like "primer cache"
end

