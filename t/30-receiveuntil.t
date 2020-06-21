use Test::Nginx::Socket;
use Testlib;

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== return value is function
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            ngx.say(testlib.repr(sock:receiveuntil('--')))
        }
    }
--- request
GET /t
--- response_body
["<function>"]

=== too few args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            ngx.say(testlib.repr(pcall(sock.receiveuntil)))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 2 or 3 arguments (including the object), but got 0"]
[false,"expecting 2 or 3 arguments (including the object), but got 1"]

=== too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, '--', {}, false)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 2 or 3 arguments (including the object), but got 4"]

=== bad pattern value type
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, nil)))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, true)))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, {})))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, function() end)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (string expected, got nil)"]
[false,"bad argument #2 to '?' (string expected, got boolean)"]
[false,"bad argument #2 to '?' (string expected, got table)"]
[false,"bad argument #2 to '?' (string expected, got function)"]

=== bad options value type
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, '--', nil)))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, '--', true)))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, '--', '')))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, '--', 2)))
            ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, '--', function() end)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #3 to '?' (table expected, got nil)"]
[false,"bad argument #3 to '?' (table expected, got boolean)"]
[false,"bad argument #3 to '?' (table expected, got string)"]
[false,"bad argument #3 to '?' (table expected, got number)"]
[false,"bad argument #3 to '?' (table expected, got function)"]

=== bad inclusive option value
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            for _, v in ipairs({'s', 1, {}}) do
                ngx.say(testlib.repr(pcall(sock.receiveuntil, sock, '--', {inclusive = v})))
            end
        }
    }
--- request
GET /t
--- response_body
[false,"bad \"inclusive\" option value type: string"]
[false,"bad \"inclusive\" option value type: number"]
[false,"bad \"inclusive\" option value type: table"]

=== empty pattern
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            ngx.say(testlib.repr(sock:receiveuntil('')))
        }
    }
--- request
GET /t
--- response_body
[null,"pattern is empty"]

=== number pattern converted to string
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef1.23deadf00d1.23trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil(1.23)
            repeat
                local r, _, err = testlib.rrepr(iter())
                ngx.say(r)
            until err
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed","trailer"]

=== iterator, no size, with trailer
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter())
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed","trailer"]
[null,"closed"]

=== iterator, no size, without trailer
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter())
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
["deadf00d"]
[null,"closed",""]
[null,"closed"]

=== iterator, size, with trailer, partial
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(5))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
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
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(7))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
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
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(5))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
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
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(16))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
[null,null,null]
["deadf00d"]
[null,null,null]
[null,"closed",""]
[null,"closed"]

=== iterator, size more than part, with trailer
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--deadf00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(16))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
[null,null,null]
["deadf00d"]
[null,null,null]
[null,"closed","trailer"]
[null,"closed"]

=== iterator, divisible size
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(4))
                ngx.say(r)
            until err
            ngx.say(testlib.repr(iter()))
        }
    }
--- request
GET /t
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

=== iterator, size and no size mixed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            ngx.say(testlib.repr(iter(4)))      -- dead
            ngx.say(testlib.repr(iter(4)))      -- beef
            ngx.say(testlib.repr(iter()))       -- ''
            ngx.say(testlib.repr(iter(4)))      -- dead
            ngx.say(testlib.repr(iter(4)))      -- ''
            ngx.say(testlib.repr(iter(4)))      -- nil, nil, nil
            ngx.say(testlib.repr(iter(4)))      -- f00d
            ngx.say(testlib.repr(iter(4)))      -- ''
            ngx.say(testlib.repr(iter()))       -- nil, nil, nil
            ngx.say(testlib.repr(iter()))       -- nil, closed, trailer
        }
    }
--- request
GET /t
--- response_body
["dead"]
["beef"]
[""]
["dead"]
[""]
[null,null,null]
["f00d"]
[""]
[null,null,null]
[null,"closed","trailer"]

=== iterator, zero size (same as no argument)
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(0))
                ngx.say(r)
            until err
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
["dead"]
["f00d"]
[null,"closed","trailer"]

=== iterator, negative size (same as no argument)
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter(-1))
                ngx.say(r)
            until err
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
["dead"]
["f00d"]
[null,"closed","trailer"]

=== iterator, size, number-like string
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            repeat
                local r, _, err = testlib.rrepr(iter('\t\t   4 \n'))
                ngx.say(r)
            until err
        }
    }
--- request
GET /t
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

=== iterator, size, floating-point number
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            ngx.say(testlib.repr(iter(2.1)))
            ngx.say(testlib.repr(iter(2.9)))
            ngx.say(testlib.repr(iter(3.9)))
            ngx.say(testlib.repr(iter(10.5)))
            ngx.say(testlib.repr(iter(1.1)))
        }
    }
--- request
GET /t
--- response_body
["de"]
["ad"]
["bee"]
["f"]
[null,null,null]

=== iterator, bad size argument type
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            ngx.say(testlib.repr(pcall(iter, nil)))
            ngx.say(testlib.repr(pcall(iter, true)))
            ngx.say(testlib.repr(pcall(iter, {})))
            ngx.say(testlib.repr(pcall(iter, 's')))
            ngx.say(testlib.repr(pcall(iter, function() end)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #1 to '?' (number expected, got nil)"]
[false,"bad argument #1 to '?' (number expected, got boolean)"]
[false,"bad argument #1 to '?' (number expected, got table)"]
[false,"bad argument #1 to '?' (number expected, got string)"]
[false,"bad argument #1 to '?' (number expected, got function)"]

=== iterator and receive mixed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('dead--beef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            ngx.say('iter: ', testlib.repr(iter(2)))                -- de
            ngx.say('receive: ', testlib.repr(sock:receive(3)))     -- ad-
            ngx.say('iter: ', testlib.repr(iter(4)))                -- -bee
            ngx.say('receive: ', testlib.repr(sock:receive(1)))     -- f
            ngx.say('iter: ', testlib.repr(iter(2)))                -- ''
            ngx.say('iter: ', testlib.repr(iter(2)))                -- nil, nil, nil
            ngx.say('iter: ', testlib.repr(iter(2)))                -- de
            ngx.say('receive: ', testlib.repr(sock:receive(4)))     -- ad--
            ngx.say('iter: ', testlib.repr(iter(2)))                -- f0
            ngx.say('receive: ', testlib.repr(sock:receive(4)))     -- 0d--
            ngx.say('iter: ', testlib.repr(iter(4)))                -- trai
            ngx.say('receive: ', testlib.repr(sock:receive(3)))     -- ler
            ngx.say('iter: ', testlib.repr(iter(4)))                -- ''
        }
    }
--- request
GET /t
--- response_body
iter: ["de"]
receive: ["ad-"]
iter: ["-bee"]
receive: ["f"]
iter: [""]
iter: [null,null,null]
iter: ["de"]
receive: ["ad--"]
iter: ["f0"]
receive: ["0d--"]
iter: ["trai"]
receive: ["ler"]
iter: [null,"closed",""]

=== iterator and receive, pattern discard
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('dead--beef--dead--f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
            local iter = sock:receiveuntil('--')
            ngx.say('iter: ', testlib.repr(iter(4)))                -- deadbeef
            ngx.say('receive: ', testlib.repr(sock:receive(4)))     -- --be
            ngx.say('iter: ', testlib.repr(iter()))                 -- ef
            ngx.say('receive: ', testlib.repr(sock:receive(2)))     -- de
            ngx.say('iter: ', testlib.repr(iter(2)))                -- ad
            ngx.say('iter: ', testlib.repr(iter()))                 -- ''
            ngx.say('receive: ', testlib.repr(sock:receive(2)))     -- f0
            ngx.say('iter: ', testlib.repr(iter(4)))                -- 0d
            ngx.say('iter: ', testlib.repr(iter()))                 -- nil, nil, nil
            ngx.say('iter: ', testlib.repr(iter()))                 -- nil, 'closed', 'trailer'
        }
    }
--- request
GET /t
--- response_body
iter: ["dead"]
receive: ["--be"]
iter: ["ef"]
receive: ["de"]
iter: ["ad"]
iter: [""]
receive: ["f0"]
iter: ["0d"]
iter: [null,null,null]
iter: [null,"closed","trailer"]

=== 2 iterators and receive mixed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('dead++beef--dead++f00d--trailer')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp()
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
GET /t
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
