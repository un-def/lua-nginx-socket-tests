use Test::Nginx::Socket;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

plan tests => repeat_each() * 2 * blocks();
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== downstream connection cosocket object has no close method
--- config
    location /t {
        content_by_lua_block {
            local sock = ngx.req.socket()
            ngx.say(sock.close == nil)
        }
    }
--- request
POST /t
deadbeefdeadf00d
--- response_body
true

=== raw downstream connection cosocket object has no close method
--- config
    location /t {
        content_by_lua_block {
            ngx.req.read_body()
            ngx.send_headers()
            ngx.flush(true)
            local sock, err = ngx.req.socket(true)
            sock:send(tostring(sock.close == nil))
        }
    }
--- request eval
"POST /t HTTP/1.0\r
Host: localhost\r
Content-Length: 5\r
\r
hello"
--- response_body chomp
true

=== regular cosocket object
--- http_config eval: $::HttpConfig
--- config
    location /mock {
        content_by_lua_block {
            ngx.say("deadf00d")
        }
    }
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.socket.tcp()
            local ok, err = sock:connect('127.0.0.1', $TEST_NGINX_SERVER_PORT)
            sock:send('GET /mock HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n')
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:close()))
            end
        }
    }
--- request
GET /t
deadbeefdeadf00d
--- response_body
[1]
[null,"closed"]
[null,"closed"]

=== regular cosocket object, close after timeout error
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
            local ok, err = sock:connect('127.0.0.1', $TEST_NGINX_SERVER_PORT)
            sock:send('GET /mock HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n')
            sock:settimeout(50)
            sock:receive('*a')
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:close()))
            end
        }
    }
--- request
GET /t
--- response_body
[1]
[null,"closed"]
[null,"closed"]

=== regular cosocket object, close after connection closed
--- http_config eval: $::HttpConfig
--- config
    location /close {
        return 444;
    }
    location /t {
        content_by_lua_block {
            local testlib = require('testlib')
            local sock = ngx.socket.tcp()
            local ok, err = sock:connect('127.0.0.1', $TEST_NGINX_SERVER_PORT)
            sock:send('GET /close HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n')
            sock:receive('*a')
            for _ = 1, 3 do
                ngx.say(testlib.repr(sock:close()))
            end
        }
    }
--- request
GET /t
--- response_body
[1]
[null,"closed"]
[null,"closed"]
