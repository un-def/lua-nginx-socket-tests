use Test::Nginx::Socket;
use Testlib;

our $MainConfig = Testlib::socket_lua_block_config(q{
    local sock = ngx.req.socket()
    while true do
        local data, err = sock:receive('*l')
        assert(not err)
        if data == '' then
            break
        end
        ngx.print(string.upper(data))
    end
});

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== error, not enough args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.receiveany)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 2 arguments (including the object), but got 0"]

=== error, not enough args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.receiveany, true, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 2 arguments (including the object), but got 3"]

=== error, bad max argument type
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            for _, value in ipairs({false, testlib.NIL, 'foo', {1}, function() end, sock}) do
                if value == testlib.NIL then
                    value = nil
                end
                ngx.say(testlib.repr(pcall(sock.receiveany, sock, value)))
            end
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad max argument)"]
[false,"bad argument #2 to '?' (bad max argument)"]
[false,"bad argument #2 to '?' (bad max argument)"]
[false,"bad argument #2 to '?' (bad max argument)"]
[false,"bad argument #2 to '?' (bad max argument)"]
[false,"bad argument #2 to '?' (bad max argument)"]

=== error, negative max argument
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.receiveany, sock, -1)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad max argument)"]

=== error, zero max argument
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.receiveany, sock, 0)))
            ngx.say(testlib.repr(pcall(sock.receiveany, sock, 0.9)))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad max argument)"]
[false,"bad argument #2 to '?' (bad max argument)"]

=== closed
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(sock:receiveany(4)))
        }
    }
--- request
GET /t
--- response_body
[null,"closed"]

=== less than response
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:receiveany(2)))
            ngx.say(testlib.repr(sock:receiveany(4)))
        }
    }
--- request
GET /t
--- response_body
["de"]
["adbe"]

=== more than response
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:receiveany(1024)))
            ngx.say(testlib.repr(sock:receive('*a')))   -- not closed
            ngx.say(testlib.repr(sock:receiveany(1024)))
            ngx.say(testlib.repr(sock:receiveany(1024)))
            ngx.say(testlib.repr(sock:receive('*a')))   -- closed
        }
    }
--- request
GET /t
--- response_body
["deadbeef"]
[""]
[null,"closed",""]
[null,"closed"]
[null,"closed"]

=== exact size
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:receiveany(4)))
            ngx.say(testlib.repr(sock:receiveany(4)))
            ngx.say(testlib.repr(sock:receive('*a')))   -- not closed
            ngx.say(testlib.repr(sock:receiveany(1)))
            ngx.say(testlib.repr(sock:receive('*a')))   -- closed
        }
    }
--- request
GET /t
--- response_body
["dead"]
["beef"]
[""]
[null,"closed",""]
[null,"closed"]

=== floating-point number
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: Testlib::socket_response_config('deadbeef')
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(sock:receiveany(2.001)))
            ngx.say(testlib.repr(sock:receiveany(2.5)))
            ngx.say(testlib.repr(sock:receiveany(2.999)))
        }
    }
--- request
GET /t
--- response_body
["de"]
["ad"]
["be"]

=== remote side sends data chunk by chunk
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            sock:send('deadbeef\n')
            ngx.say(testlib.repr(sock:receiveany(1024)))
            sock:send('foo')
            sock:send('bar\n')
            ngx.say(testlib.repr(sock:receiveany(4)))
            ngx.say(testlib.repr(sock:receiveany(4)))
            sock:send('\n')
            ngx.say(testlib.repr(sock:receiveany(4)))
        }
    }
--- request
GET /t
--- response_body
["DEADBEEF"]
["FOOB"]
["AR"]
[null,"closed",""]
