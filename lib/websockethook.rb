require 'faye/websocket'
require 'json'
require 'eventmachine'

class WebSocketHook
  DEFAULT_HOST       = 'ws://websockethook.io'
  DEFAULT_SLEEP      = 0.1
  DEFAULT_KEEP_ALIVE = true
  DEFAULT_PING       = 20

  def initialize(options = {})
    @stopping = false
    initialize_host options
    initialize_pause options
    initialize_keep_alive options
    initialize_ping options
  end

  def listen(id=nil, &block)
    fail 'Block must be provided' unless block && block.is_a?(Proc)
    begin
      @stopping = false
      listener(id, &block)
      restart = @keep_alive && !@stopping
      if restart
        block.call type: 'restart', message: 'restarting connection since it was lost'
        sleep 5
      end
    end while restart
  end

  def stop
    @stopping = true
    stop_em
  end

  private

  def initialize_host(options = {})
    @host = options[:host] || DEFAULT_HOST
    fail 'Host (:host) must be a URL' unless @host.is_a?(String)
  end

  def initialize_pause(options = {})
    @pause = options[:sleep] || DEFAULT_SLEEP
    fail 'Pause (:pause) must be a float or integer' unless @pause.is_a?(Float) || @pause.is_a?(Integer)
  end

  def initialize_keep_alive(options = {})
    @keep_alive = options[:keep_alive] || DEFAULT_KEEP_ALIVE
    fail 'Keep Alive (:keep_alive) must be a boolean (true/false)' unless @keep_alive == true || @keep_alive == false
  end

  def initialize_ping(options = {})
    @ping = options[:ping] || DEFAULT_PING
    fail 'Ping (:ping) must be an integer' unless @ping.is_a?(Integer)
  end

  def stop_em
    EM.stop
  rescue
  end

  def listener(id, &block)
    websocket(block) do |ws|
      ws.on :open do
        block.call type: 'open'
        ws.send({type:'register',id:id}.to_json)
      end
      ws.on :message do |message|
        data = nil
        begin
          data = JSON.parse(message.data, symbolize_names: true)
        rescue => ex
          block.call type: 'error', message: "Message received, but couldn't parse: #{ex.message}"
        end
        content = data.inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo }
        data[:data][:url] = "#{@host.sub('ws://','http://')}#{data[:data][:path]}" if data[:type]=='registered' && data[:data] && data[:data][:path]
        block.call(content) if data && block
      end

      handle_ws(ws, :error, block) { @hooks.each { |hook| ws.send({ type: 'register', id: hook }.to_json) } }
      handle_ws(ws, :close, block) { stop_em }
      handle_ws(ws, :error, block) { stop_em }
    end
  end

  def websocket(callback_block, &socket_block)
    EM.run do
      ws_settings = { ping: @ping }
      ws = Faye::WebSocket::Client.new(@host, nil, ws_settings)
      socket_block.call(ws)
    end
    callback_block.call(type: 'stopped')
  rescue => ex
    callback_block.call type: 'error', message: ex.message
  rescue Interrupt
    stop
    callback_block.call(type: 'stopped')
  end

  def handle_ws(ws, action, callback_block, &_block)
    ws.on action do
      callback_block.call(type: action.to_s)
    end
  end
end
