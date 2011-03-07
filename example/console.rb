require 'rubygems'
require 'eventmachine'
require 'stringio'

module Console
  PROMPT = "\n>> ".freeze

  def post_init
    send_data PROMPT
    send_data "\0"
  end

  def receive_data data
    return close_connection if data =~ /exit|quit/

    begin
      @ret, @out, $stdout = :exception, $stdout, StringIO.new
      @ret = eval(data, scope, '(rirb)')
    rescue StandardError, ScriptError, Exception, SyntaxError
      $! = RuntimeError.new("unknown exception raised") unless $!
      print $!.class, ": ", $!, "\n"

      trace = []
      $!.backtrace.each do |line|
        trace << "\tfrom #{line}"
        break if line =~ /\(rirb\)/
      end
      
      puts trace
    ensure
      $stdout, @out = @out, $stdout
      @out.rewind
      @out = @out.read
    end

    send_data @out unless @out.empty?
    send_data "=> #{@ret.inspect}" unless @ret == :exception
    send_data "\0\n>> \0"
  end

  # def send_data data
  #   p ['server send', data]
  #   super
  # end

  def scope
    @scope ||= instance_eval{ binding }
  end

  def handle_error
    $! = RuntimeError.new("unknown exception raised") unless $!
    print $!.class, ": ", $!, "\n"

    trace = []
    $!.backtrace.each do |line|
      trace << "\\tfrom \#{line}"
      break if line =~ /\(rirb\)/
    end
    
    puts trace
  end

  def self.start port = 7331
    EM.run{
      @server ||= EM.start_server '127.0.0.1', port, self
    }
  end

  def self.stop
    @server.close_connection if @server
    @server = nil
  end
end

module RIRB
  def connection_completed
    p 'connected to console'
  end

  def receive_data data
    # p ['receive', data]
    (@buffer ||= BufferedTokenizer.new("\0")).extract(data).each do |d|
      process(d)
    end
  end

  def process data
    if data.strip == '>>'
      while l = Readline.readline('>> ')
        unless l.nil? or l.strip.empty?
          Readline::HISTORY.push(l)
          send_data l
          break
        end
      end
    else
      puts data
    end
  end

  def unbind
    p 'disconnected'
    EM.stop_event_loop
  end
  
  def self.connect host = 'localhost', port = 7331
    require 'readline'
    EM.run{
      trap('INT'){ exit }
      @connection.close_connection if @connection
      @connection = EM.connect host, port, self do |c|
        c.instance_eval{ @host, @port = host, port }
      end
    }
  end
  attr_reader :host, :port
end

if __FILE__ == $0
  EM.run{
    if ARGV[0] == 'server'
      Console.start
    elsif ARGV[0] == 'client'
      RIRB.connect
    else
      puts "#{$0} <server|client>"
      EM.stop
    end
  }
end
