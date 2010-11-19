module Primer
  module Helpers
    
    module ERB
      def primer(cache_key, &block)
        result = Primer.cache.compute(cache_key) do
          capture_output(&block)
        end
        @_out_buf.concat(result)
      end
      
    private
      
      def capture_output(&block)
        original_buffer = @_out_buf
        result = @_out_buf = ''
        block.call
        @_out_buf = original_buffer
        result
      end
    end
    
  end
end

