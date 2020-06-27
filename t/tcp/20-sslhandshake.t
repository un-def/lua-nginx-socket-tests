use Test::Nginx::Socket;
use Testlib;

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== error, not enough args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::ssl_socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.sslhandshake)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket sslhandshake: expecting 1 ~ 5 arguments (including the object), but seen 0"]

=== error, too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::ssl_socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.sslhandshake, true, true, true, true, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket sslhandshake: expecting 1 ~ 5 arguments (including the object), but seen 6"]

=== closed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::ssl_socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(sock:sslhandshake()))
        }
    }
--- request
GET /t
--- response_body
[null,"closed"]

=== handshake failed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:sslhandshake()))
            ngx.say(testlib.repr(sock:sslhandshake()))
        }
    }
--- request
GET /t
--- response_body
[null,"handshake failed"]
[null,"closed"]

=== no reused_session arg, session userdata is returned
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::ssl_socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:sslhandshake()))
            ngx.say(testlib.repr(sock:sslhandshake(nil)))
        }
    }
--- request
GET /t
--- response_body
["<userdata>"]
["<userdata>"]

=== reused_session = true, session userdata is not returned
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::ssl_socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:sslhandshake(false)))
            ngx.say(testlib.repr(sock:sslhandshake(false)))
        }
    }
--- request
GET /t
--- response_body
[true]
[true]

=== ssl_verify argument = true, error, self-signed certificate
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::ssl_socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:sslhandshake(nil, nil, true)))
        }
    }
--- request
GET /t
--- response_body
[null,"18: self signed certificate"]
