VERSION=0.1

SOURCES := $(wildcard *.fnl)
COMPILED := $(patsubst %.fnl,%.lua,$(SOURCES))

%.lua: %.fnl
	fennel --compile --correlate $< > $@

all: $(COMPILED)

release: releases/backpackless-win32.zip releases/backpackless-$(VERSION)_all.deb

releases/backpackless-win32.zip: $(COMPILED)
	love-release -W32
	zip -d $@ "backpackless-win32/lovec.exe"

releases/backpackless-$(VERSION)_all.deb: $(COMPILED)
	love-release -D -v $(VERSION)

upload-windows: releases/backpackless-win32.zip
	butler push $^ awkravchuk/backpackless:windows --userversion $(VERSION)

upload-linux:  releases/backpackless-$(VERSION)_all.deb
	butler push $^ awkravchuk/backpackless:linux --userversion $(VERSION)

upload: upload-windows upload-linux

count:
	cloc *.fnl --force-lang=clojure

clean:
	rm -rf $(COMPILED) releases

.PHONY: clean upload upload-windows upload-linux release
