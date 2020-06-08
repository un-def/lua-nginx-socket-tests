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

=== 2 iterators and receive mixed
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.req.socket()
            local iter1 = sock:receiveuntil('--')
            local iter2 = sock:receiveuntil('++')
            ngx.say('receive: ', testlib.repr(sock:receive(2)))     -- de
            ngx.say('iter1: ', testlib.repr(iter1(3)))              -- ad+
            ngx.say('iter2: ', testlib.repr(iter2(3)))              -- +be
            ngx.say('iter1: ', testlib.repr(iter1(16)))             -- ef
            ngx.say('iter2: ', testlib.repr(iter2(16)))             -- dead
            ngx.say('receive: ', testlib.repr(sock:receive(2)))     -- f0
            ngx.say('iter1: ', testlib.repr(iter1(16)))             -- nil, nil, nil
            ngx.say('iter1: ', testlib.repr(iter1(16)))             -- 0d
            ngx.say('iter1: ', testlib.repr(iter1(16)))             -- nil, nil, nil
            ngx.say('iter2: ', testlib.repr(iter2(16)))             -- nil, nil, nil
            ngx.say('receive: ', testlib.repr(sock:receive(3)))     -- tra
            ngx.say('iter1: ', testlib.repr(iter1(2)))              -- il
            ngx.say('iter2: ', testlib.repr(iter2(2)))              -- er
            ngx.say('iter1: ', testlib.repr(iter1(2)))              -- nil, closed, ''
            ngx.say('iter2: ', testlib.repr(iter2(2)))              -- nil, closed
            ngx.say('receive: ', testlib.repr(sock:receive(3)))     -- nil, closed
        }
    }
--- request
POST /t
dead++beef--dead++f00d--trailer
--- response_body
receive: ["de"]
iter1: ["ad+"]
iter2: ["+be"]
iter1: ["ef"]
iter2: ["dead"]
receive: ["f0"]
iter1: [null,null,null]
iter1: ["0d"]
iter1: [null,null,null]
iter2: [null,null,null]
receive: ["tra"]
iter1: ["il"]
iter2: ["er"]
iter1: [null,"closed",""]
iter2: [null,"closed"]
receive: [null,"closed"]
