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
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(pcall(sock.connect)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket connect: expecting 2, 3, or 4 arguments (including the object), but seen 0"]

=== error, too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(pcall(sock.connect, true, true, true, true, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket connect: expecting 2, 3, or 4 arguments (including the object), but seen 6"]

=== error, bad host
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(pcall(testlib.tcp_connect, sock, 'foo://bar')))
        }
    }
--- request
GET /t
--- response_body
[false,"failed to parse host name \"foo:\/\/bar\": invalid host"]

=== error, bad port
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(pcall(testlib.tcp_connect, sock, nil, -1)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad port number: -1"]

=== error, connection refused
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(pcall(testlib.tcp_connect, sock, nil, 1)))
        }
    }
--- request
GET /t
--- response_body
[false,"connection refused"]

=== connect not connected
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(testlib.tcp_connect(sock)))
        }
    }
--- request
GET /t
--- response_body
[1]

=== connect already connected
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(testlib.tcp_connect(sock, nil, $TEST_NGINX_SERVER_PORT)))
            ngx.say(testlib.repr(testlib.tcp_connect(sock)))
        }
    }
--- request
GET /t
--- response_body
[1]
[1]
