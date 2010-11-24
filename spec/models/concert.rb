class Concert < ActiveRecord::Base
  has_many :performances, :dependent => :destroy
  include Primer::Watcher
end

