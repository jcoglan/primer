class Concert < ActiveRecord::Base
  belongs_to :calendar
  has_many :performances, :dependent => :destroy
  include Primer::Watcher
end

