require 'spec_helper'
require 'websockethook'
require 'securerandom'
require 'rest-client'

describe WebSocketHook do
  include Wrong

  it 'can initialize' do
    expect do
      ws = WebSocketHook.new
    end.to_not raise_error
  end

  it 'can register a hook' do
    ws = WebSocketHook.new
    data = []
    t = Thread.new { ws.listen { |msg| data << msg } }

    eventually do
      data.any? do |line|
        line[:type] == 'registered'
      end
    end

    ws.stop
    t.kill
  end

  it 'can register a hook with an id' do
    id = "test_#{SecureRandom.hex(4)}"
    ws = WebSocketHook.new
    ws.register id
    data = []
    t = Thread.new { ws.listen { |msg| data << msg } }

    eventually do
      data.any? do |line|
        line[:type] == 'registered' && line[:data][:id] == id
      end
    end

    ws.stop
    t.kill
  end

  it 'can trigger a hook with data' do
    id = "test_#{SecureRandom.hex(4)}"
    ws = WebSocketHook.new
    ws.register id
    data = []
    t = Thread.new { ws.listen { |msg| data << msg } }
    hook_url = ''

    check_eventually data do |line|
      found = line[:type] == 'registered' && line[:data][:id] == id
      hook_url = line[:data][:url] if found
      found
    end

    RestClient.post(hook_url,this_is_a:'test')

    check_eventually data do |line|
      line[:type] == 'hook' && line[:data] == {this_is_a:'test'}
    end

    ws.stop
    t.kill
  end

  def check_eventually(data, &block)
    eventually do
      data.any? do |line|
        block.yield(line)
      end
    end
  end
end
