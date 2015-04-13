require 'spec_helper'

require 'websockethook'

describe WebSocketHook do

  it 'can initialize' do
    expect {
      ws = WebSocketHook.new
      }.to_not raise_error
  end
end