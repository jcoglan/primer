module Primer
  class RealTime
    
    class PublishRestriction
      def incoming(message, callback)
        channel = message['channel']
        return callback.call(message) if Faye::Channel.meta?(channel)
        
        password = message['ext'] && message['ext']['password']
        unless password == RealTime.password
          message['error'] = Faye::Error.ext_mismatch
        end
        
        callback.call(message)
      end
    end
    
  end
end

