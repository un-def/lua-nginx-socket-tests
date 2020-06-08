use Test::Nginx::Socket;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== return value is function
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            ngx.say(testlib.repr(sock:receiveuntil('--')))
        }
    }
--- request
POST /t
deadbeef--deadf00d--trailer
--- response_body
["<function>"]

=== iterator, no size, with trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter())
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--trailer
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed","trailer"]
[null,"closed"]

=== iterator, no size, without trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter())
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed",""]
[null,"closed"]

=== iterator, size, with trailer, partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(5))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--trailer
--- response_body
["deadb"]
["eef"]
[null,null,null]
["deadf"]
["00d"]
[null,null,null]
["trail"]
[null,"closed","er"]
[null,"closed"]

=== iterator, size, with trailer, empty partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(7))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--trailer
--- response_body
["deadbee"]
["f"]
[null,null,null]
["deadf00"]
["d"]
[null,null,null]
["trailer"]
[null,"closed",""]
[null,"closed"]

=== iterator, size, without trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(5))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--
--- response_body
["deadb"]
["eef"]
[null,null,null]
["deadf"]
["00d"]
[null,null,null]
[null,"closed",""]
[null,"closed"]

=== iterator, size more than part, without trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(16))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--
--- response_body
["deadbeef"]
[null,null,null]
["deadf00d"]
[null,null,null]
[null,"closed",""]
[null,"closed"]

=== iterator, size more than part, with trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(16))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--trailer
--- response_body
["deadbeef"]
[null,null,null]
["deadf00d"]
[null,null,null]
[null,"closed","trailer"]
[null,"closed"]

=== iterator, divisible size
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(4))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--dead--f00d--trailer
--- response_body
["dead"]
["beef"]
[""]
[null,null,null]
["dead"]
[""]
[null,null,null]
["f00d"]
[""]
[null,null,null]
["trai"]
[null,"closed","ler"]
[null,"closed"]
