use Test::Nginx::Socket;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== iterator, no size, with trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--', {inclusive = true})
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
["deadbeef--"]
["deadf00d--"]
[null,"closed","trailer"]
[null,"closed"]

=== iterator, no size, without trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--', {inclusive = true})
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
["deadbeef--"]
["deadf00d--"]
[null,"closed",""]
[null,"closed"]

=== iterator, size, with trailer, partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--', {inclusive = true})
            repeat
                local r, _, err = testlib.rrepr(iter(4))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef--deadf00d--trailer
--- response_body
["dead"]
["beef"]
["--"]
[null,null,null]
["dead"]
["f00d"]
["--"]
[null,null,null]
["trai"]
[null,"closed","ler"]
[null,"closed"]

=== iterator, size, with trailer, empty partial
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--', {inclusive = true})
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
["f--"]
[null,null,null]
["deadf00"]
["d--"]
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
            local iter = sock:receiveuntil('--', {inclusive = true})
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
["eef--"]
[null,null,null]
["deadf"]
["00d--"]
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
            local iter = sock:receiveuntil('--', {inclusive = true})
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
["deadbeef--"]
[null,null,null]
["deadf00d--"]
[null,null,null]
[null,"closed",""]
[null,"closed"]

=== iterator, size less than pattern length
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('-==-', {inclusive = true})
            repeat
                local r, _, err = testlib.rrepr(iter(2))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
POST /t
deadbeef-==-deadf00d-==-trailer
--- response_body
["de"]
["ad"]
["be"]
["ef"]
["-==-"]
[null,null,null]
["de"]
["ad"]
["f0"]
["0d"]
["-==-"]
[null,null,null]
["tr"]
["ai"]
["le"]
[null,"closed","r"]
[null,"closed"]

=== iterator, size more than part, with trailer
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('--', {inclusive = true})
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
["deadbeef--"]
[null,null,null]
["deadf00d--"]
[null,null,null]
[null,"closed","trailer"]
[null,"closed"]

=== iterator, size and no size mixed
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter = sock:receiveuntil('-==-', {inclusive = true})
            ngx.say(testlib.repr(iter(4)))      -- dead
            ngx.say(testlib.repr(iter(5)))      -- beef-==-
            ngx.say(testlib.repr(iter()))       -- nil, nil, nil
            ngx.say(testlib.repr(iter(4)))      -- dead
            ngx.say(testlib.repr(iter(1)))      -- -==-
            ngx.say(testlib.repr(iter()))       -- nil, nil, nil
            ngx.say(testlib.repr(iter(3)))      -- f00
            ngx.say(testlib.repr(iter()))       -- d-==-
            ngx.say(testlib.repr(iter()))       -- nil, closed, trailer
            ngx.say(testlib.repr(iter()))       -- nil, closed
        }
    }
--- request
POST /t
deadbeef-==-dead-==-f00d-==-trailer
--- response_body
["dead"]
["beef-==-"]
[null,null,null]
["dead"]
["-==-"]
[null,null,null]
["f00"]
["d-==-"]
[null,"closed","trailer"]
[null,"closed"]
