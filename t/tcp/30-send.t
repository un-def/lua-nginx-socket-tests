use Test::Nginx::Socket;
use Testlib;

our $MainConfig = Testlib::socket_lua_block_config(q{
    local sock = ngx.req.socket()
    repeat
        local data, err, partial = sock:receive('*l')
        ngx.say(data or partial)
    until err
});

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== error, not enough args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.send)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 2 arguments (including the object), but got 0"]

=== error, too many args
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.send, true, true, true)))
        }
    }
--- request
GET /t
--- response_body
[false,"expecting 2 arguments (including the object), but got 3"]

=== error, bad value - userdata
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.send, sock, sock)))
            ngx.say(testlib.repr(pcall(sock.send, sock, {'foo', sock})))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad data type userdata found)"]
[false,"bad argument #2 to '?' (bad data type userdata found)"]

=== error, bad value - function
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.send, sock, function() end)))
            ngx.say(testlib.repr(pcall(sock.send, sock, {'foo', function() end, 'bar'})))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (string, number, boolean, nil, or array table expected, got function)"]
[false,"bad argument #2 to '?' (bad data type function found)"]

=== error, bad value - non-array table
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            ngx.say(testlib.repr(pcall(sock.send, sock, {'foo', 'bar', baz = 'qux'})))
            ngx.say(testlib.repr(pcall(sock.send, sock, {'foo', {'bar', {'baz', k = 1}}, 'qux'})))
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (non-array table found)"]
[false,"bad argument #2 to '?' (non-array table found)"]

=== error, bad value - table with non-strings
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)

            local tbl = {'foo', nil, 'bar'}
            for _, value in ipairs({false, testlib.NIL, sock, function() end}) do
                if value == testlib.NIL then
                    value = nil
                end
                tbl[2] = value
                ngx.say(testlib.repr(pcall(sock.send, sock, tbl)))
            end
        }
    }
--- request
GET /t
--- response_body
[false,"bad argument #2 to '?' (bad data type boolean found)"]
[false,"bad argument #2 to '?' (bad data type nil found)"]
[false,"bad argument #2 to '?' (bad data type userdata found)"]
[false,"bad argument #2 to '?' (bad data type function found)"]

=== not connected
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(false)
            ngx.say(testlib.repr(sock:send('foo')))
        }
    }
--- request
GET /t
--- response_body
[null,"closed"]

=== ok, allowed argument types
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            for _, value in ipairs({'foo', '', 21, 12.44, false, testlib.NIL, {}, {'bar', 'baz'}}) do
                if value == testlib.NIL then
                    value = nil
                end
                ngx.say(testlib.repr(sock:send(value)))
                sock:send('\n')
                ngx.say(testlib.repr(sock:receive('*l')))
            end
        }
    }
--- request
GET /t
--- response_body
[3]
["foo"]
[0]
[""]
[2]
["21"]
[5]
["12.44"]
[5]
["false"]
[3]
["nil"]
[0]
[""]
[6]
["barbaz"]

=== ok, nested table
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            local tbl = {'alfa ', {'bravo ', {{'charlie '}, 'delta ', 'echo '}}, 'foxtrot ', 'golf'}
            ngx.say(testlib.repr(sock:send(tbl)))
            sock:send('\n')
            ngx.say(testlib.repr(sock:receive('*l')))
        }
    }
--- request
GET /t
--- response_body
[42]
["alfa bravo charlie delta echo foxtrot golf"]

=== ok, nested table with numbers
--- http_config eval: $Testlib::HttpConfig
--- main_config eval: $::MainConfig
--- config
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = testlib.tcp(true)
            local tbl = {'foo', {1.23, {-432, 0.33}, 'bar', 'baz'}, 'qux'}
            ngx.say(testlib.repr(sock:send(tbl)))
            sock:send('\n')
            ngx.say(testlib.repr(sock:receive('*l')))
        }
    }
--- request
GET /t
--- response_body
[24]
["foo1.23-4320.33barbazqux"]
