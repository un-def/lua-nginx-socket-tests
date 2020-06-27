package Testlib;

use strict;
use warnings;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

my $MainConfigSocket = qq{
    env TEST_SOCKET_PORT;
    stream {
        server {
            listen $ENV{'TEST_SOCKET_PORT'};
            content_by_lua_block {
                %s
            }
        }
    }
};

my $MainConfigSSLSocket = qq{
    env TEST_SOCKET_PORT;
    stream {
        server {
            listen $ENV{'TEST_SOCKET_PORT'} ssl;
            ssl_certificate ../../test.crt;
            ssl_certificate_key ../../test.key;
            content_by_lua_block {
                %s
            }
        }
    }
};

sub socket_lua_block_config {
    my ($block) = @_;
    return sprintf($MainConfigSocket, $block);
}

sub socket_response_config {
    my ($response) = @_;
    return sprintf($MainConfigSocket, "ngx.print('$response')");
};

sub ssl_socket_lua_block_config {
    my ($block) = @_;
    return sprintf($MainConfigSSLSocket, $block);
}

sub ssl_socket_response_config {
    my ($response) = @_;
    return sprintf($MainConfigSSLSocket, "ngx.print('$response')");
};
