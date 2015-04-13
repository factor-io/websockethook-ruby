require 'faye/websocket'
require 'json'
require 'eventmachine'

class WebSocketHook
  DEFAULT_HOST = 'ws://web.sockethook.io'

  def initialize(options = {})
    @host       = options[:host] || DEFAULT_HOST
    @pause      = options[:sleep] || 0.1
    @stay_alive = options[:stay_alive] || true
    @ping       = options[:ping] || 20
    hooks       = options[:hooks] || []
    @stopping   = false
    @hooks      = []

    raise 'Host (:host) must be a URL' unless @host.is_a?(String)
    raise 'Pause (:pause) must be a float or integer' unless @pause.is_a?(Float) || @pause.is_a?(Integer)
    raise 'Stay Alive (:stay_alive) must be a boolean (true/false)' unless @stay_alive == true || @stay_alive == false
    raise 'Ping (:ping) must be an integer' unless @ping.is_a?(Integer)
    raise 'Stopping (:stopping) must be boolean (true/false)' unless @stopping == true || @stopping == false
    raise 'Hooks (:hooks) must be an array' unless hooks.is_a?(Array)

    hooks.each {|hook| register(hook) }
  end

  def register(id)
    raise "Hook id '#{id}' must be a String" unless id.is_a?(String)
    raise "Hook id must only be alphanumeric, '_', '.', or '_'" unless /^[a-zA-Z0-9\-_\.]*$/ === id
    @hooks << id unless @hooks.include?(id)
  end

  def unregister(id)
    @hooks.delete(id)
  end

  def listen(&block)
    raise 'Block must be provided' unless block && block.is_a?(Proc)
    begin
      @stopping = false
      listener(&block)
      restart = @stay_alive && !@stopping
      if restart
        block.call type:'restart', message:'restarting connection since it was lost'
        sleep 5
      end
    end while restart
  end

  def stop
    @stopping = true
    stop_em
  end

  private

  def stop_em
    begin
      EM.stop
    rescue
    end
  end

  def listener(&block)
    EM.run do
      ws_settings = {ping: @ping}
      ws = Faye::WebSocket::Client.new(@host, nil, ws_settings)

      ws.on :message do |message|
        data = nil
        begin
          data = JSON.parse(message.data, symbolize_names:true)
        rescue => ex
          block.call type:'error', message: "Message received, but couldn't parse: #{ex.message}"
        end
        content = data.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo }
        block.call(content) if data && block
      end

      ws.on :open do
        block.call(type:'open') if block
        @hooks.each do |hook|
          ws.send({type:'register', id:hook}.to_json)
        end
      end

      ws.on :close do
        block.call(type:'close') if block
        stop_em
      end

      ws.on :error do
        block.call(type:'error') if block
        stop_em
      end
    end
    block.call(type:'stopped')
  rescue => ex
    block.call type:'error', message:ex.message
  rescue Interrupt
    stop
    block.call(type:'stopped')
  end
end