use Test::Nginx::Socket;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

plan tests => repeat_each() * 3 * blocks();
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
--- no_error_log
[error]

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
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed",""]
--- no_error_log
[error]

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
        }
    }
--- request
POST /t
deadbeef
--- response_body
[null,"closed","deadbeef"]
--- no_error_log
[error]

=== size, after close, partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            for _ = 1, 4 do
                ngx.say(testlib.repr(sock:receive(5)))
            end
        }
    }
--- request
POST /t
deadbeef
--- response_body
["deadb"]
[null,"closed","eef"]
[null,"closed"]
[null,"closed"]
--- error_log
attempt to receive data on a closed socket

=== size, after close, empty partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            for _ = 1, 4 do
                ngx.say(testlib.repr(sock:receive(4)))
            end
        }
    }
--- request
POST /t
deadbeef
--- response_body
["dead"]
["beef"]
[null,"closed",""]
[null,"closed"]
--- error_log
attempt to receive data on a closed socket

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
--- no_error_log
[error]

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
--- no_error_log
[error]

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
"POST /t\r\ndeadbeef\r\ndeadf00d\r\n"
--- more_headers
Content-Length: 20
--- response_body
["deadbeef\r\nde"]
[null,"closed","adf00d\r\n"]
--- no_error_log
[error]

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
--- no_error_log
[error]

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
--- request
POST /t
deadbeefdeadf00d
--- response_body
["deadbeefdeadf00d"]
[""]
[""]
[""]
--- no_error_log
[error]

=== no arg
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            for _ = 1, 4 do
                ngx.say(testlib.repr(sock:receive()))
            end
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
[null,"closed","deadbeefdeadf00d"]
[null,"closed"]
[null,"closed"]
[null,"closed"]
--- error_log
attempt to receive data on a closed socket
