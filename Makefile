OPENRESTY_PREFIX=/usr/local/openresty

.PHONY: test

test:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -v -r t
