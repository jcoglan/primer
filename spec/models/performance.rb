class Performance < ActiveRecord::Base
  belongs_to :artist
  belongs_to :concert
  include Primer::Watcher
end

