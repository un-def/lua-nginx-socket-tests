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
            ngx.say(testlib.repr(pcall(sock.getreusedtimes)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 1 argument (including the object), but got 0"]

=== error, too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.getreusedtimes, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 1 argument (including the object), but got 2"]

=== closed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(sock:getreusedtimes()))
        }
    }
--- request
GET /t
--- response_body
[null,"closed"]

=== not reused
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:getreusedtimes()))
        }
    }
--- request
GET /t
--- response_body
[0]

=== reused three times
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            for _ = 1, 3 do
                local sock = testlib.tcp(true)
                sock:setkeepalive()
            end
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:getreusedtimes()))
        }
    }
--- request
GET /t
--- response_body
[3]
