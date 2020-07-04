use Test::Nginx::Socket;
use Testlib;

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== error, not enough args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.setkeepalive)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 1 to 3 arguments (including the object), but got 0"]

=== error, too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.setkeepalive, true, true, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 1 to 3 arguments (including the object), but got 4"]

=== error, bad timeout value
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            for _, value in ipairs({false, 'foo', {}}) do
                local sock = testlib.tcp(true)
                ngx.say(testlib.repr(pcall(sock.setkeepalive, sock, value)))
            end
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (number expected, got boolean)"]
[false,"bad argument #2 to '?' (number expected, got string)"]
[false,"bad argument #2 to '?' (number expected, got table)"]

=== error, bad pool size value
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            for _, value in ipairs({-1, 0, true, 'foo'}) do
                ngx.say(testlib.repr(pcall(sock.setkeepalive, sock, nil, value)))
            end
            ngx.say(testlib.repr(sock:setkeepalive()))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #3 to '?' (bad \"pool_size\" option value: -1)"]
[false,"bad argument #3 to '?' (bad \"pool_size\" option value: 0)"]
[false,"bad argument #3 to '?' (number expected, got boolean)"]
[false,"bad argument #3 to '?' (number expected, got string)"]
[1]

=== bad timeout value closes connection for some reason
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.setkeepalive, sock, 'foo')))
            ngx.say(testlib.repr(sock:receive(4)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (number expected, got string)"]
[null,"closed"]

=== bad pool size value does not close connection
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.setkeepalive, sock, nil, 'foo')))
            ngx.say(testlib.repr(sock:receive(4)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #3 to '?' (number expected, got string)"]
["dead"]

=== negative timeout is ok
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:setkeepalive(-1)))
        }
    }
--- request
GET /t
--- response_body
[1]

=== number-like string timeout is ok
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:setkeepalive('1000')))
        }
    }
--- request
GET /t
--- response_body
[1]

=== number-like string pool size is ok
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:setkeepalive(nil, '1000')))
        }
    }
--- request
GET /t
--- response_body
[1]

=== closed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(sock:setkeepalive()))
        }
    }
--- request
GET /t
--- response_body
[null,"closed"]

=== connected
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:setkeepalive()))
            ngx.say(testlib.repr(sock:setkeepalive()))
        }
    }
--- request
GET /t
--- response_body
[1]
[null,"closed"]

=== unread data in buffer
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            sock:receive(1)
            ngx.say(testlib.repr(sock:setkeepalive()))
        }
    }
--- request
GET /t
--- response_body
[null,"unread data in buffer"]
