class Watchable
  include Primer::Watcher
  watch_calls_to :name, :is_called?
  
  def initialize(name)
    @name = name
  end
  
  def name
    @name
  end
  
  def is_called?(name)
    @name == name
  end
end

