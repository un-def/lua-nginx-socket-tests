use Test::Nginx::Socket;
use Testlib;

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== not connected, pattern should not be checked
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.socket.tcp()
            for _, pattern in ipairs({0, 1, -1, 'bad', {}, false}) do
                ngx.say(testlib.repr(sock:receive(pattern)))
            end
        }
    }
--- request
GET /t
--- response_body
[null,"closed"]
[null,"closed"]
[null,"closed"]
[null,"closed"]
[null,"closed"]
[null,"closed"]

=== size, partial
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(5))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive(5)))
            ngx.say(testlib.repr(sock:receive(5)))
        }
    }
--- request
GET /t
--- response_body
["deadb"]
["eefde"]
["adf00"]
[null,"closed","d"]
[null,"closed"]
[null,"closed"]

=== size, empty partial
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(8))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive(8)))
             ngx.say(testlib.repr(sock:receive(8)))
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed",""]
[null,"closed"]
[null,"closed"]

=== size, more than body
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(20))
                ngx.say(r)
            until error
            ngx.say(testlib.repr(sock:receive(20)))
            ngx.say(testlib.repr(sock:receive(20)))
        }
    }
--- request
GET /t
--- response_body
[null,"closed","deadbeef"]
[null,"closed"]
[null,"closed"]

=== size, zero, does not close connection
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            for _ = 1, 2 do
                ngx.say(testlib.repr(sock:receive(0)))
            end
            ngx.say(testlib.repr(sock:receive(8)))
            for _ = 1, 2 do
                ngx.say(testlib.repr(sock:receive(0)))
            end
            ngx.say(testlib.repr(sock:receive(1)))
            for _ = 1, 2 do
                ngx.say(testlib.repr(sock:receive(0)))
            end
        }
    }
--- request
GET /t
--- response_body
[""]
[""]
["deadf00d"]
[""]
[""]
[null,"closed",""]
[null,"closed"]
[null,"closed"]

=== size, float
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(sock:receive(2.1)))
            ngx.say(testlib.repr(sock:receive(2.9)))
            ngx.say(testlib.repr(sock:receive(3.1)))
            ngx.say(testlib.repr(sock:receive(3.9)))

        }
    }
--- request
GET /t
--- response_body
["de"]
["ad"]
["bee"]
["fde"]

=== size, number-like
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(' \t 5\r\n '))
                ngx.say(r)
            until err
        }
    }
--- request
GET /t
--- response_body
["deadb"]
["eefde"]
["adf00"]
[null,"closed","d"]

=== size, CR are preserved
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef\r\ndeadf00d\r\n')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(12))
                ngx.say(r)
            until err
        }
    }
--- request
GET /t
--- response_body
["deadbeef\r\nde"]
[null,"closed","adf00d\r\n"]

=== bad pattern, nil
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(pcall(sock.receive, sock, nil)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument)"]

=== bad pattern, unsupported string pattern
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(pcall(sock.receive, sock, 'foo')))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument: foo)"]

=== bad pattern, boolean
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(pcall(sock.receive, sock, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument)"]

=== bad pattern, table
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(pcall(sock.receive, sock, {})))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument)"]

=== bad pattern, negative number
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(pcall(sock.receive, sock, -1)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument)"]

=== bad pattern, negative number-like string
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeefdeadf00d')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(pcall(sock.receive, sock, '-1')))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument)"]

=== pattern, '*a'
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef\r\ndeadf00d\r\n')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            for _ = 1, 4 do
                ngx.say(testlib.repr(sock:receive('*a')))
            end
            sock:close()
            for _ = 1, 2 do
                ngx.say(testlib.repr(sock:receive('*a')))
            end
        }
    }
--- request
GET /t
--- response_body
["deadbeef\r\ndeadf00d\r\n"]
[""]
[""]
[""]
[null,"closed"]
[null,"closed"]

=== pattern, '*a', does not close connection
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef\r\ndeadf00d\r\n')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            ngx.say(testlib.repr(sock:receive('*a')))
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:receive(1)))
            end
        }
    }
--- request
GET /t
--- response_body
["deadbeef\r\ndeadf00d\r\n"]
[null,"closed",""]
[null,"closed"]
[null,"closed"]

=== pattern, '*l'
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive('*l'))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive('*l')))
            ngx.say(testlib.repr(sock:receive('*l')))
        }
    }
--- request
GET /t
--- response_body
[""]
["dead"]
[""]
["beef"]
[null,"closed","deadf00d"]
[null,"closed"]
[null,"closed"]

=== pattern, '*l', trailing newline
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r\n\r\n\n')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive('*l'))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive('*l')))
            ngx.say(testlib.repr(sock:receive('*l')))
        }
    }
--- request
GET /t
--- response_body
[""]
["dead"]
[""]
["beef"]
["deadf00d"]
[""]
[""]
[null,"closed",""]
[null,"closed"]
[null,"closed"]

=== pattern, no arg
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive())
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive()))
            ngx.say(testlib.repr(sock:receive()))
        }
    }
--- request
GET /t
--- response_body
[""]
["dead"]
[""]
["beef"]
[null,"closed","deadf00d"]
[null,"closed"]
[null,"closed"]

=== pattern, no arg, trailing newline
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r\n\r\n\n')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            repeat
                local r, _, err = testlib.rrepr(sock:receive())
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive()))
            ngx.say(testlib.repr(sock:receive()))
        }
    }
--- request
GET /t
--- response_body
[""]
["dead"]
[""]
["beef"]
["deadf00d"]
[""]
[""]
[null,"closed",""]
[null,"closed"]
[null,"closed"]

=== timeout
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_lua_block_config('ngx.sleep(1); ngx.print("slow response")')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp_connect()
            sock:settimeout(50)
            ngx.say(testlib.repr(sock:receive('*a')))
            sock:close()
        }
    }
--- request
GET /t
--- response_body
[null,"timeout",""]
