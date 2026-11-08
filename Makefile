# GNU Makefile for Linux & macOS.

OS := $(shell uname)
ifeq ($(OS), Darwin)
MFILE_OS=Makefile.macosx
# The Boron interpreter is built from the src/boron submodule.
BORON_SUB=src/obj/bin/boron
BORON ?= $(BORON_SUB)
else
MFILE_OS=Makefile
BORON ?= boron
endif
BORON_DEP=$(filter $(BORON_SUB),$(BORON))

# Note: xu4 is hardcoded to look in /usr & /usr/local only!
DESTDIR ?= /usr/local

MODULES=render.pak Ultima-IV.mod U4-Upgrade.mod
REND=module/render


all: src/xu4 $(MODULES)

src/xu4:
	make -C src -f $(MFILE_OS) xu4

$(BORON_SUB):
	make -C src -f $(MFILE_OS) obj/bin/boron

render.pak: $(REND)/shader/*.glsl $(REND)/shader/*.png $(REND)/font/cfont.png | $(BORON_DEP)
	$(BORON) -s tools/pack-xu4.b -f $(REND) -o $@

Ultima-IV.mod: module/Ultima-IV/*.b | $(BORON_DEP)
	$(BORON) -s tools/pack-xu4.b module/Ultima-IV

U4-Upgrade.mod: module/U4-Upgrade/*.b | $(BORON_DEP)
	$(BORON) -s tools/pack-xu4.b module/U4-Upgrade

# src/xu4 is phony so the sub-make always checks for source changes.
.PHONY: src/xu4 clean download mod snapshot app install-app

# macOS application bundle.  The original game files are not included;
# put ultima4.zip (or an "ultima4" folder) in ~/Library/Application Support/xu4.
APP=XU4.app

app: src/xu4 $(MODULES) u4upgrad.zip
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp src/macosx/Info.plist $(APP)/Contents/
	printf 'APPL????' > $(APP)/Contents/PkgInfo
	cp src/xu4 $(APP)/Contents/MacOS/
	strip -x $(APP)/Contents/MacOS/xu4
	cp icons/xu4.icns $(MODULES) u4upgrad.zip $(APP)/Contents/Resources/
	codesign --force --sign - $(APP)

install-app: app
	rm -rf /Applications/$(APP)
	cp -R $(APP) /Applications/

clean:
	make -C src -f $(MFILE_OS) clean
	rm -f $(MODULES)
	rm -rf $(APP)

mod: $(MODULES)

download: ultima4.zip u4upgrad.zip

ultima4.zip:
	curl -sSL -o $@ http://ultima.thatfleminggent.com/ultima4.zip

u4upgrad.zip:
	curl -sSL -o $@ http://sourceforge.net/projects/xu4/files/Ultima%204%20VGA%20Upgrade/1.3/u4upgrad.zip

install: src/xu4 $(MODULES) u4upgrad.zip
	mkdir -p $(DESTDIR)/bin $(DESTDIR)/share/xu4
	install -m 755 -s src/xu4 $(DESTDIR)/bin/xu4
	install -m 644 -t $(DESTDIR)/share/xu4 $(MODULES) u4upgrad.zip
	install -D -m 644 icons/shield.png $(DESTDIR)/share/icons/hicolor/48x48/apps/xu4.png
	install -D -m 644 dist/xu4.desktop $(DESTDIR)/share/applications/xu4.desktop

snapshot: $(MODULES)
	@rm -f project.tar.gz
	copr -c
	tools/cbuild windows
	tools/cbuild linux
	cp /tmp/xu4-linux.tar.gz /tmp/xu4-win32.zip ../web/download
