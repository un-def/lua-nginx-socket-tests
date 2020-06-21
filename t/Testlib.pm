package Testlib;

our $HttpConfig = q{
    lua_package_path "$prefix/../?.lua;;";
};

my $MainConfig = qq{
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

sub socket_lua_block_config ($) {
    my ($block) = @_;
    return sprintf($MainConfig, $block);
}

sub socket_response_config ($) {
    my ($response) = @_;
    return sprintf($MainConfig, "ngx.print('$response')");
};
