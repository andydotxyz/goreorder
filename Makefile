.PHONY: dist install clean clean-dist dev-build

CUR_SHA=$(shell git log -n1 --pretty='%h')
CUR_BRANCH=$(shell git branch --show-current)
VERSION=$(shell git describe --exact-match --tags $(CUR_SHA) 2>/dev/null || echo $(CUR_BRANCH)-$(CUR_SHA))

GIT_PATH:=github.com/metal3d/goreorder
PACKAGE:=$(GIT_PATH)/...
COMMAND_PACKAGE:=$(GIT_PATH)/cmd/goreorder

DIST_CC:=podman run
DIST_CC_OPTS:=--rm -i --userns keep-id -v $(PWD):/go/src/github.com/metal3d/goreorder:z -w /go/src/github.com/metal3d/goreorder -e CGO_ENABLED=0 docker.io/golang:1.18
CC=go
CC_OPTS=-ldflags "-X main.version=$(VERSION)"

install:
	go install -v $(CC_OPTS) $(PACKAGE)

uninstall:
	go clean -i ./...

dev-build:
	go build -v $(CC_OPTS) -o goreorder ./cmd/goreorder/*.go 

.ONESHELL:
dist: clean-dist
	mkdir -p dist
	$(MAKE) dist/goreorder-linux-amd64
	$(MAKE) dist/goreorder-darwin-amd64
	$(MAKE) dist/goreorder-windows-amd64.exe
	$(MAKE) dist/goreorder-freebsd-amd64
	# stripping
	strip dist/goreorder-linux-amd64 || true
	strip dist/goreorder-darwin-amd64 || true
	strip dist/goreorder-windows-amd64.exe || true
	strip dist/goreorder-freebsd-amd64 || true
	# sign
	for i in $$(find dist -type f); do
		echo "signing $$i"
		echo "sha256: $$(sha256sum $$i)" >> $$i.sha256
	done



dist/goreorder-linux-amd64:
	@mkdir -p dist
ifeq ($(strip $(_CNT)),true)
	GOOS=linux GOARCH=amd64 $(CC) build $(CC_OPTS) -o $@ $(COMMAND_PACKAGE)
else
	$(DIST_CC) -e _CNT=true $(DIST_CC_OPTS) make $@
endif

dist/goreorder-darwin-amd64:
	@mkdir -p dist
ifeq ($(strip $(_CNT)),true)
	GOOS=darwin GOARCH=amd64 $(CC) build $(CC_OPTS)  -o $@ $(COMMAND_PACKAGE)
else
	$(DIST_CC) -e _CNT=true $(DIST_CC_OPTS) make $@
endif

dist/goreorder-windows-amd64.exe:
	@mkdir -p dist
ifeq ($(strip $(_CNT)),true)
	GOOS=windows GOARCH=amd64 $(CC) build $(CC_OPTS) -o $@ $(COMMAND_PACKAGE)
else
	$(DIST_CC) -e _CNT=true $(DIST_CC_OPTS) make $@
endif

dist/goreorder-freebsd-amd64:
	@mkdir -p dist
ifeq ($(strip $(_CNT)),true)
	GOOS=freebsd GOARCH=amd64 $(CC) build $(CC_OPTS) -o $@ $(COMMAND_PACKAGE)
else
	$(DIST_CC) -e _CNT=true $(DIST_CC_OPTS) make $@
endif

clean-dist:
	rm -rf dist

clean: clean-dist
	rm -f ./goreorder


test:
	go test ./ordering -v -cover
