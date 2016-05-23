require 'websocket-client-simple'
require 'json'

class WebSocketHook
  attr_reader :host

  DEFAULT_HOST       = 'wss://websockethook.io'
  DEFAULT_SLEEP      = 0.1
  DEFAULT_KEEP_ALIVE = true
  DEFAULT_PING       = 20

  def initialize(options = {})
    @stopping = false
    initialize_host options
    # initialize_keep_alive options
  end

  def listen(id=nil, &callback)
    @ws = WebSocket::Client::Simple.connect(@host)

    this = self
    @ws.on(:open)    { this.on_open(id, &callback) }
    @ws.on(:message) {|message| this.on_message(message, &callback) }
    @ws.on(:close)   { callback.call :closed }
    @ws.on(:error)   { |er| callback.call :error, er }

    block(&callback)
  end

  def stop
    unblock
    @ws.close
  end

  def on_open(id=nil, &callback)
    callback.call :open
    @ws.send({type:'register', id: id}.to_json) if id
  end

  def on_message(message, &callback)
    if message && message.data
        data = JSON.parse(message.data) 
        if data['type'] == 'registered'
          callback.call :registered, data['data']
        end
        callback.call :hook, {'id'=>data['id'], 'data' => data['data']} if data['type'] == 'hook'
      end
  end

  def block(&callback)
    begin
      sleep 0.1
    end while !@stopping
    callback.call :stopped
    @stopping = false
  end

  def unblock
    @stopping = true
  end

  def initialize_host(options = {})
    @host = options[:host] || DEFAULT_HOST
    fail 'Host (:host) must be a URL' unless @host.is_a?(String)
  end

end
