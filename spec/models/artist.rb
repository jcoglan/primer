class Artist < ActiveRecord::Base
  include Primer::Watcher
  include Primer::Lazyness
  
  has_many :performances
  has_many :concerts, :through => :performances
  
  belongs_to :calendar
  has_many :upcoming_gigs, :through => :calendar, :source => :gigs
end

