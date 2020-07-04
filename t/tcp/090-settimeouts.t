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
            ngx.say(testlib.repr(pcall(sock.settimeouts)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket settimout: expecting 4 arguments (including the object) but seen 0"]

=== error, too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.settimeouts, true, true, true, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"ngx.socket settimout: expecting 4 arguments (including the object) but seen 5"]

=== negative number
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.settimeouts, sock, 1000, -1, 1000)))
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
            ngx.say(testlib.repr(pcall(sock.settimeouts, sock, 1000, '-1', 1000)))
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
                ngx.say(testlib.nargs(sock:settimeouts(1000, value, 1000)))
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
            ngx.say(testlib.nargs(sock:settimeouts(1000, 2000, 3000)))
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
            ngx.say(testlib.nargs(sock:settimeouts(1000, 2000, 3000)))
        }
    }
--- request
GET /t
--- response_body
0
