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
            ngx.say(testlib.repr(pcall(sock.settimeout)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket settimout: expecting 2 arguments (including the object) but seen 0"]

=== error, too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.settimeout, true, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket settimout: expecting 2 arguments (including the object) but seen 3"]

=== negative number
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.settimeout, sock, -1)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad timeout value"]

=== number-like string, negative number
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.settimeout, sock, '-1')))
        }
    }
--- request
GET /t
--- response_body
[false,"bad timeout value"]

=== values with invalid type are silently converted to 0 (due to `lua_tonumber` C function)
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            for _, value in ipairs({false, testlib.NIL, 'foo', {1}, function() end, sock}) do
                if value == testlib.NIL then
                    value = nil
                end
                ngx.say(testlib.nargs(sock:settimeout(value)))
            end
        }
    }
--- request
GET /t
--- response_body
0
0
0
0
0
0

=== closed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.nargs(sock:settimeout(1000)))
        }
    }
--- request
GET /t
--- response_body
0

=== connected
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.nargs(sock:settimeout(1000)))
        }
    }
--- request
GET /t
--- response_body
0
