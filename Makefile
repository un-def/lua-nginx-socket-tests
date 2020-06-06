OPENRESTY_PREFIX := /usr/local/openresty
T := t

.PHONY: test

test:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -v -r $(T)
