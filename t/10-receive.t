use Test::Nginx::Socket;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== size, partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(5))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive(5)))
            ngx.say(testlib.repr(sock:receive(5)))
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
["deadb"]
["eefde"]
["adf00"]
[null,"closed","d"]
[null,"closed"]
[null,"closed"]

=== size, empty partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(8))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(sock:receive(8)))
             ngx.say(testlib.repr(sock:receive(8)))
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed",""]
[null,"closed"]
[null,"closed"]

=== size, more than body
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(20))
                ngx.say(r)
            until error
            ngx.say(testlib.repr(sock:receive(20)))
            ngx.say(testlib.repr(sock:receive(20)))
        }
    }
--- request
POST /t
deadbeef
--- response_body
[null,"closed","deadbeef"]
[null,"closed"]
[null,"closed"]

=== size, zero
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            for _ = 1, 4 do
                ngx.say(testlib.repr(sock:receive(0)))
            end
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
[""]
[""]
[""]
[""]

=== size, negative
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            ngx.say(testlib.repr(pcall(sock.receive, sock, -1)))
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument)"]

=== size, number-like
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(' \t 5\r\n '))
                ngx.say(r)
            until err
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
["deadb"]
["eefde"]
["adf00"]
[null,"closed","d"]

=== size, CR are preserved
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local r, _, err = testlib.rrepr(sock:receive(12))
                ngx.say(r)
            until err
        }
    }
--- request eval
"POST /t
deadbeef\r\ndeadf00d\r\n"
--- more_headers
Content-Length: 20
--- response_body
["deadbeef\r\nde"]
[null,"closed","adf00d\r\n"]

=== pattern, bad pattern
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local repr = require('testlib').repr
            local sock = ngx.req.socket()
            ngx.say(repr(pcall(sock.receive, sock, 'foo')))
        }
    }
--- request
POST /t
deadbeef
--- response_body
[false,"bad argument #2 to '?' (bad pattern argument: foo)"]

=== pattern, '*a'
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            for _ = 1, 4 do
                ngx.say(testlib.repr(sock:receive('*a')))
            end
        }
    }
--- request eval
"POST /t
deadbeef\r\ndeadf00d\r\n"
--- more_headers
Content-Length: 20
deadbeefdeadf00d
--- response_body
["deadbeef\r\ndeadf00d\r\n"]
[""]
[""]
[""]

=== pattern, '*l'
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local repr, _, err = testlib.rrepr(sock:receive('*l'))
                ngx.say(repr)
            until err
            ngx.say(testlib.repr(sock:receive('*l')))
            ngx.say(testlib.repr(sock:receive('*l')))
        }
    }
--- request eval
"POST /t
\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r"
--- more_headers
Content-Length: 28
--- response_body
[""]
["dead"]
[""]
["beef"]
[null,"closed","deadf00d"]
[null,"closed"]
[null,"closed"]

=== pattern, '*l', trailing newline
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local repr, _, err = testlib.rrepr(sock:receive('*l'))
                ngx.say(repr)
            until err
            ngx.say(testlib.repr(sock:receive('*l')))
            ngx.say(testlib.repr(sock:receive('*l')))
        }
    }
--- request eval
"POST /t
\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r\n\r\n\n"
--- more_headers
Content-Length: 32
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
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local repr, _, err = testlib.rrepr(sock:receive())
                ngx.say(repr)
            until err
            ngx.say(testlib.repr(sock:receive()))
            ngx.say(testlib.repr(sock:receive()))
        }
    }
--- request eval
"POST /t
\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r"
--- more_headers
Content-Length: 28
--- response_body
[""]
["dead"]
[""]
["beef"]
[null,"closed","deadf00d"]
[null,"closed"]
[null,"closed"]

=== pattern, no arg, trailing newline
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local repr, _, err = testlib.rrepr(sock:receive())
                ngx.say(repr)
            until err
            ngx.say(testlib.repr(sock:receive()))
            ngx.say(testlib.repr(sock:receive()))
        }
    }
--- request eval
"POST /t
\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r\n\r\n\n"
--- more_headers
Content-Length: 32
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
--- http_config eval: $::HttpConfig
--- config
    location /slow {
        content_by_lua_block {
            ngx.sleep(1)
            ngx.say("slow response")
        }
    }
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.socket.tcp()
            sock:settimeout(50)
            local ok, err = sock:connect('127.0.0.1', $TEST_NGINX_SERVER_PORT)
            sock:send('GET /slow HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n')
            ngx.say(testlib.repr(sock:receive(1024)))
            sock:close()
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
[null,"timeout",""]
