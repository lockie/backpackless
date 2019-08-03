VERSION=0.1

SOURCES := $(wildcard *.fnl)
COMPILED := $(patsubst %.fnl,%.lua,$(SOURCES))

%.lua: %.fnl
	fennel --compile --correlate $< > $@

all: releases/backpackess-win32.zip releases/backpackless-$(VERSION)_all.deb

releases/backpackess-win32.zip: $(COMPILED)
	love-release -W32

releases/backpackless-$(VERSION)_all.deb: $(COMPILED)
	love-release -D -v $(VERSION)

count:
	cloc *.fnl --force-lang=clojure

clean:
	rm -rf $(COMPILED) releases

.PHONY: clean
