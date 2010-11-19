require 'spec_helper'

describe Primer::Cache do
  before do
    @cache  = Primer::Cache::Memory.new
    @person = Person.create(:name => "Abe")
  end
  
  after do
    @person.destroy
  end
  
  def compute_value
    @cache.compute("/people/abe/name") { @person.name }
  end
  
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
  
  describe "when the value is already known" do
    before { compute_value }
    
    it "returns the value of the block" do
      compute_value.should == "Abe"
    end
    
    it "does not call the implementation" do
      @person.should_not_receive(:name)
      compute_value
    end
  end
end

