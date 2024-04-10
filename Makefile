PROJECT ?= radxa-archive-keyring
PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
MANDIR ?= $(PREFIX)/share/man

.PHONY: all
all: build

#
# Maintaince
#
.PHONY: new-key
new-key:
	gpg --delete-secret-key "Radxa APT Key $(shell date +%Y) <dev@radxa.com>" 2>/dev/null || true
	gpg --delete-key "Radxa APT Key $(shell date +%Y) <dev@radxa.com>" 2>/dev/null || true
# Follow Debian keyring life time
# https://ftp-master.debian.org/keys.html
	gpg --quick-gen-key "Radxa APT Key $(shell date +%Y) <dev@radxa.com>" rsa4096 sign $(shell date -I -d "8 years")
	gpg --output keyrings/radxa-archive-keyring-$(shell date +%Y).gpg --export "Radxa APT Key $(shell date +%Y) <dev@radxa.com>"
	gpg --output keyrings/radxa-archive-keyring-$(shell date +%Y).asc --armor --export-secret-keys "Radxa APT Key $(shell date +%Y) <dev@radxa.com>"

#
# Test
#
.PHONY: test
test:

#
# Build
#
.PHONY: build
build: build-doc

SRC-DOC		:=	.
DOCS		:=	$(SRC-DOC)/SOURCE
.PHONY: build-doc
build-doc: $(DOCS)

$(SRC-DOC):
	mkdir -p $(SRC-DOC)

.PHONY: $(SRC-DOC)/SOURCE
$(SRC-DOC)/SOURCE: $(SRC-DOC)
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-doc clean-deb

.PHONY: clean-doc
clean-doc:
	rm -rf $(DOCS)

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/${PROJECT} debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.postrm.debhelper debian/*.substvars

#
# Release
#
.PHONY: dch
dch: debian/changelog
	EDITOR=true gbp dch --ignore-branch --multimaint-merge --commit --release --dch-opt=--upstream

.PHONY: deb
deb: debian
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b

.PHONY: release
release:
	gh workflow run .github/workflows/new_version.yml --ref $(shell git branch --show-current)
