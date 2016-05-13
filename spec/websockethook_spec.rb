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
    expect(@logger).to receive(:log).with({type: 'open'})
    expect(@logger).to receive(:log).with({type: 'close'})
    expect(@logger).to receive(:log).with({type: 'stopped'})

    @ws.listen 'test' do |msg|
      @logger.log(msg)
      @ws.stop
    end

  end

  it 'can trigger a hook with data' do
    expect(@logger).to receive(:log).with({type: 'open'})
    expect(@logger).to receive(:log).with({type: 'registered', data: anything()})
    expect(@logger).to receive(:log).with({type: 'hook', id: anything(), data: {this_is_a:'test'}})
    expect(@logger).to receive(:log).with({type: 'close'})
    expect(@logger).to receive(:log).with({type: 'stopped'})

    @ws.listen do |msg|
      @logger.log(msg)
      
      if msg[:type] == 'registered'
        hook_url = msg[:data][:url]
        RestClient.post(hook_url,this_is_a:'test')        
      end

      @ws.stop if msg[:type] == 'hook'
    end    
  end

  it 'can register a custom id' do
    id = "test_#{SecureRandom.hex(4)}"

    expect(@logger).to receive(:log).with({type: 'open'})
    expect(@logger).to receive(:log).with({type: 'registered', data: anything()})
    expect(@logger).to receive(:log).with({type: 'registered', data: {id:id, path:"/hook/#{id}",url:"http://websockethook.io/hook/#{id}"}})
    expect(@logger).to receive(:log).with({type: 'close'})
    expect(@logger).to receive(:log).with({type: 'stopped'})

    @ws.listen id do |msg|
      @logger.log(msg)
      
      if msg[:type] == 'registered' && msg[:data][:id] == id
        @ws.stop
      end
    end    
  end
end
