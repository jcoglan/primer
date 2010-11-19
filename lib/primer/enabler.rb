module Primer
  module Enabler
    def enable!
      @enabled = true
      on_enable
    end
    
    def disable!
      @enabled = false
      on_disable
    end
    
    def enabled?
      !!@enabled
    end
  end
end

