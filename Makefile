tom: tom.m
	clang -Wall -Wconversion -Werror -fobjc-arc -framework CoreGraphics -framework Foundation -framework IOKit tom.m -o tom

.PHONY: clean

clean:
	rm tom

.PHONY: install

install: tom
	mkdir -p "$(HOME)/.local/bin/"
	cp tom "$(HOME)/.local/bin/"
	mkdir -p "$(HOME)/Library/LaunchAgents/"
	sed "s|TOM_PATH|$(HOME)/.local/bin/tom|g" tom.plist >"$(HOME)/Library/LaunchAgents/tom.plist"
	launchctl load "$(HOME)/Library/LaunchAgents/tom.plist"
