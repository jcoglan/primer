class Person < ActiveRecord::Base
  include Primer::Watcher
  
  def all_attributes
    [id, the_name]
  end
  
  def the_name
    name
  end
end

