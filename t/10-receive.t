use Test::Nginx::Socket;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

repeat_each(2);
plan tests => repeat_each() * 3 * blocks();
run_tests();

__DATA__

=== TEST 1: pattern, bad pattern
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

=== TEST 2: size, partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local n, data, err, partial = testlib.nargs(sock:receive(5))
                ngx.say(testlib.repr(n, data, err, partial))
            until err
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
[1,"deadb",null,null]
[1,"eefde",null,null]
[1,"adf00",null,null]
[3,null,"closed","d"]
--- no_error_log
[error]

=== TEST 3: size, no partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            repeat
                local n, data, err, partial = testlib.nargs(sock:receive(8))
                ngx.say(testlib.repr(n, data, err, partial))
                if err then break end
            until err
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
[1,"deadbeef",null,null]
[1,"deadf00d",null,null]
[3,null,"closed",""]
--- no_error_log
[error]

=== TEST 4: size, more than body
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local repr = require('testlib').repr
            local sock = ngx.req.socket()
            repeat
                local data, err, partial = sock:receive(20)
                ngx.say(repr(data, err, partial))
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

=== TEST 4: after close
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            ngx.say(testlib.repr(sock:receive(20)))
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
--- error_log
attempt to receive data on a closed socket
