require 'faye/websocket'
require 'json'
require 'eventmachine'

class WebSocketHook
  DEFAULT_HOST = 'ws://web.sockethook.io'

  def initialize(options = {})
    @stopping = false
    @hooks    = []
    initialize_host options
    initialize_pause options
    initialize_keep_alive options
    initialize_ping options
    initialize_hooks options
  end

  def initialize_host(options = {})
    @host = options[:host] || DEFAULT_HOST
    raise 'Host (:host) must be a URL' unless @host.is_a?(String)
  end

  def initialize_pause(options = {})
    @pause = options[:sleep] || 0.1
    raise 'Pause (:pause) must be a float or integer' unless @pause.is_a?(Float) || @pause.is_a?(Integer)
  end

  def initialize_keep_alive(options = {})
    @keep_alive = options[:keep_alive] || true
    raise 'Keep Alive (:keep_alive) must be a boolean (true/false)' unless @keep_alive == true || @keep_alive == false
  end

  def initialize_ping(options = {})
    @ping = options[:ping] || 20
    raise 'Ping (:ping) must be an integer' unless @ping.is_a?(Integer)
  end

  def initialize_hooks(options = {})
    hooks  = options[:hooks] || []
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
      restart = @keep_alive && !@stopping
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
    websocket(block) do |ws|
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
        @hooks.each {|hook| ws.send({type:'register', id:hook}.to_json) }
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
  end

  def websocket(callback_block, &socket_block)
    EM.run do
      ws_settings = {ping: @ping}
      ws = Faye::WebSocket::Client.new(@host, nil, ws_settings)
      socket_block.call(ws)
    end
    callback_block.call(type:'stopped')
  rescue => ex
    callback_block.call type:'error', message:ex.message
  rescue Interrupt
    stop
    callback_block.call(type:'stopped')
  end
end