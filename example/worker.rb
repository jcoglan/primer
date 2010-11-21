require File.expand_path(File.dirname(__FILE__)) + '/environment'

EM.run {
  # Just for logging, does not affect cache operation
  Primer.bus.subscribe do |message|
    puts "Got message: #{ message.inspect }"
  end
  
  # Make cache pick up data change messages
  Primer.cache.bind_to_bus
}

