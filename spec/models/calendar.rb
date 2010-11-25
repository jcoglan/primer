class Calendar < ActiveRecord::Base
  has_many :artists
  has_many :gigs, :class_name => 'Concert'
  
  include Primer::Watcher
end

