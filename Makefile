OPENRESTY_PREFIX := /usr/local/openresty
export TEST_SOCKET_PORT ?= 1985
export PERL5LIB := $(CURDIR)/t:$(PERL5LIB)
export PATH := $(OPENRESTY_PREFIX)/nginx/sbin:$(PATH)

.PHONY: test
test: T := t
test:
	prove -v -r $(T)
