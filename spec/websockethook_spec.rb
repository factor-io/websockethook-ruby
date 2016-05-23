require 'spec_helper'
require 'websockethook'
require 'securerandom'
require 'rest-client'

describe WebSocketHook do
  before :each do
      @ws     = WebSocketHook.new
      @logger = double('@logger', log: true)
  end

  it 'can open and close' do
    expect(@logger).to receive(:log).with(:open)
    expect(@logger).to receive(:log).with(:closed)
    expect(@logger).to receive(:log).with(:stopped)

    @ws.listen do |msg|
      @logger.log(msg)
      @ws.stop
    end
  end

  it 'can trigger a hook with data' do
    expect(@logger).to receive(:log).with(:open,nil)
    expect(@logger).to receive(:log).with(:registered, {'id'=>anything(),'path'=>anything()})
    expect(@logger).to receive(:log).with(:hook, {'id'=> anything(), 'data' => {'this_is_a' => 'test'}})
    expect(@logger).to receive(:log).with(:closed,nil)
    expect(@logger).to receive(:log).with(:stopped,nil)

    @ws.listen do |type,msg|
      @logger.log(type,msg)
      
      if type == :registered
        host = @ws.host.sub(/^ws/,'http')
        url = "#{host}#{msg['path']}"
        RestClient.post(url,this_is_a:'test')        
      end

      if type == :hook
        @ws.stop 
      end
    end    
  end

  it 'can register a custom id' do
    id = "test_#{SecureRandom.hex(4)}"

    expect(@logger).to receive(:log).with(:open, nil)
    expect(@logger).to receive(:log).with(:registered, {'id'=>anything(),'path'=>anything()})
    expect(@logger).to receive(:log).with(:registered, {'id'=>id, 'path'=>"/hook/#{id}"})
    expect(@logger).to receive(:log).with(:closed, nil)
    expect(@logger).to receive(:log).with(:stopped, nil)

    @ws.listen id do |type,msg|
      @logger.log(type,msg)
      
      if type == :registered && msg['id'] == id
        @ws.stop
      end
    end    
  end
end
