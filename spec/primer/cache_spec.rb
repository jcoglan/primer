require 'spec_helper'

describe Primer::Cache do
  before do
    @cache  = Primer.cache = Primer::Cache::Memory.new
    @person = Person.create(:name => "Abe")
  end
  
  after do
    @person.destroy
  end
  
  def compute_value
    @cache.compute("/people/abe/name") { @person.name }
  end
  
  describe "#compute" do
    it "returns the value of the block" do
      compute_value.should == "Abe"
    end
    
    it "calls the implementation to get the value" do
      @person.should_receive(:name)
      compute_value
    end
    
    it "stores the result of the computation" do
      @cache.should_receive(:put).with("/people/abe/name", "Abe")
      compute_value
    end
    
    it "notes that the value is related to some ActiveRecord data" do
      @cache.should_receive(:relate).with("/people/abe/name", [["ActiveRecord", "Person", @person.id, "name"]])
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
        @cache.should_receive(:invalidate).with("/people/abe/name")
        @person.update_attribute(:name, "Aaron")
      end
      
      it "does not invalidate the cache when unrelated data changes" do
        @cache.should_not_receive(:invalidate)
        @person.update_attribute(:age, 28)
      end
    end
  end
  
  describe "#invalidate" do
    before { @cache.put("/some/key", "value") }
    
    it "removes the key from the cache" do
      @cache.invalidate("/some/key")
      @cache.get("/some/key").should be_nil
    end
    
    describe "when a cache value has been generated from a computation" do
      before { compute_value }
      
      it "removes existing relations between the model and the cache" do
        @cache.invalidate("/people/abe/name")
        @cache.should_not_receive(:invalidate)
        @person.update_attribute(:name, "Weeble")
      end
    end
  end
end

