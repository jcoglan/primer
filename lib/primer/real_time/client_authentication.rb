module Primer
  class RealTime
    
    class ClientAuthentication
      def outgoing(message, callback)
        channel = message['channel']
        return callback.call(message) if Faye::Channel.meta?(channel)
        
        message['ext'] ||= {}
        message['ext']['password'] = RealTime.password
        
        callback.call(message)
      end
    end
    
  end
end

