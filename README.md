[![Code Climate](https://codeclimate.com/github/factor-io/websockethook-ruby.png)](https://codeclimate.com/github/factor-io/websockethook-ruby)
[![Test Coverage](https://codeclimate.com/github/factor-io/websockethook-ruby/coverage.png)](https://codeclimate.com/github/factor-io/websockethook-ruby)
[![Dependency Status](https://gemnasium.com/factor-io/websockethook-ruby.svg)](https://gemnasium.com/factor-io/websockethook-ruby)
[![Build Status](https://travis-ci.org/factor-io/websockethook-ruby.svg)](https://travis-ci.org/factor-io/websockethook-ruby)
[![Gem Version](https://badge.fury.io/rb/websockethook.svg)](http://badge.fury.io/rb/websockethook)

# WebSocketHook.io Ruby Library


## Usage example
```ruby
require 'websockethook'

wsh = WebSocketHook.new

wsh.register 'foo'

wsh.listen do |message|
  puts "#{Time.now.to_s}: #{message}"
end

```

**make call from shell*
```shell
> curl http://web.sockethook.io/hook/foo --data "foo=bar"
```