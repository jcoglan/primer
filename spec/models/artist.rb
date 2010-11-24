class Artist < ActiveRecord::Base
  has_many :performances
  has_many :concerts, :through => :performances
  include Primer::Watcher
end

