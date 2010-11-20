require 'spec_helper'

class Context
  include Primer::Helpers::ERB
  attr_accessor :name
  
  def initialize(name)
    @name = name
  end
end

shared_examples_for "erb helper" do
  let(:context) { Context.new("Aaron") }
  let(:output)  { erb.render(context) }
  
  before do
    Primer.cache = Primer::Cache::Memory.new
  end
  
  describe "#primer" do
    describe "with an empty cache" do
      it "renders the contents of the block" do
        output.should == "Welcome\nHello, Aaron\nThanks\n"
      end
      
      it "uses the model to get data" do
        context.should_receive(:name).and_return("Abe")
        output.should == "Welcome\nHello, Abe\nThanks\n"
      end
      
      it "writes the block result to the cache" do
        Primer.cache.should_receive(:put).with("/cache/key", "Hello, Aaron")
        output
      end
    end
    
    describe "with a value in the cache" do
      before { Primer.cache.put("/cache/key", "Text from the cache") }
      
      it "does not use the model to get data" do
        context.should_not_receive(:name)
        output
      end
      
      it "renders the cached value into the template" do
        output.should == "Welcome\nText from the cache\nThanks\n"
      end
    end
  end
end

describe "Sinatra ERB templates" do
  let(:erb) { Tilt[:erb].new("spec/templates/page.erb", 0, :outvar => "@_out_buf") }
  it_should_behave_like "erb helper"
end

