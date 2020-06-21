use Test::Nginx::Socket;
use Testlib;

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== close
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:close()))
            end
        }
    }
--- request
GET /t
deadbeefdeadf00d
--- response_body
[1]
[null,"closed"]
[null,"closed"]

=== close not connected
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.socket.tcp()
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:close()))
            end
        }
    }
--- request
GET /t
deadbeefdeadf00d
--- response_body
[null,"closed"]
[null,"closed"]
[null,"closed"]

=== close after timeout error
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_lua_block_config('ngx.sleep(1); ngx.print("slow response")')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            sock:settimeout(50)
            ngx.say(testlib.repr(sock:receive('*a')))
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:close()))
            end
        }
    }
--- request
GET /t
--- response_body
[null,"timeout",""]
[1]
[null,"closed"]
[null,"closed"]

=== close after connection closed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(sock:receive('*a')))
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:close()))
            end
        }
    }
--- request
GET /t
--- response_body
["deadf00d"]
[1]
[null,"closed"]
[null,"closed"]
