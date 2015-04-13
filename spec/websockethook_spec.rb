require 'spec_helper'

require 'websockethook'

describe WebSocketHook do
  it 'can initialize' do
    expect do
      ws = WebSocketHook.new
    end.to_not raise_error
  end
end
