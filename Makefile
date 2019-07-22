SHELL := /bin/bash
NAME := tlint
PKG := github.com/transferwise/tlint

PREFIX?=$(shell pwd)
BUILDDIR := ${PREFIX}/cross

VERSION := $(shell cat VERSION.txt)
GITCOMMIT ?= $(shell git rev-parse HEAD)
CTIMEVAR=-X $(PKG)/version.GITCOMMIT=$(GITCOMMIT) -X $(PKG)/version.VERSION=$(VERSION)
GO_LDFLAGS=-ldflags "-w $(CTIMEVAR)"
GO_LDFLAGS_STATIC=-ldflags "-w $(CTIMEVAR) -extldflags -static"

GOOSARCHES = darwin/amd64 darwin/386 freebsd/amd64 freebsd/386 linux/arm linux/arm64 linux/amd64 linux/386 solaris/amd64 windows/amd64 windows/386

GO := go

all: clean build fmt lint staticcheck vet install

.PHONY: install
install:
	@echo "+ $@"
	$(GO) install -a -tags "$(BUILDTAGS)" ${GO_LDFLAGS} .

.PHONY: build
build: $(NAME)

$(NAME): $(wildcard *.go) $(wildcard */*.go) VERSION.txt
	@echo "+ $@"
	$(GO) build -tags "$(BUILDTAGS)" ${GO_LDFLAGS} -o $(NAME) .

.PHONY: static
static: clean ## Builds a static executable.
	@echo "+ $@"
	CGO_ENABLED=$(CGO_ENABLED) $(GO) build -tags "$(BUILDTAGS) static_build" ${GO_LDFLAGS_STATIC} -o $(NAME) .

.PHONY: fmt
fmt: ## Verifies all files have been `gofmt`ed.
	@echo "+ $@"
	@if [[ ! -z "$(gofmt -s -l . | grep -v '.pb.go:' | grep -v '.twirp.go:' | grep -v vendor | tee /dev/stderr)" ]]; then \
		exit 1; \
	fi

.PHONY: lint
lint: ## Verifies `golint` passes.
	@echo "+ $@"
	@if [[ ! -z "$(golint ./... | grep -v '.pb.go:' | grep -v '.twirp.go:' | grep -v vendor | tee /dev/stderr)" ]]; then \
		exit 1; \
	fi

.PHONY: vet
vet: ## Verifies `go vet` passes.
	@echo "+ $@"
	@if [[ ! -z "$($(GO) vet $(shell $(GO) list ./... | grep -v vendor) | tee /dev/stderr)" ]]; then \
		exit 1; \
	fi

.PHONY: staticcheck
staticcheck: ## Verifies `staticcheck` passes.
	@echo "+ $@"
	@if [[ ! -z "$(staticcheck $(shell $(GO) list ./... | grep -v vendor) | tee /dev/stderr)" ]]; then \
		exit 1; \
	fi

define buildrelease
GOOS=$(1) GOARCH=$(2) CGO_ENABLED=0 $(GO) build \
	 -o $(BUILDDIR)/$(NAME)-$(1)-$(2) \
	 -a -tags "$(BUILDTAGS) static_build netgo" \
	 -installsuffix netgo ${GO_LDFLAGS_STATIC} .;
endef

.PHONY: release
release: *.go VERSION.txt ## Builds the cross-compiled binaries, naming them in such a way for release (eg. binary-GOOS-GOARCH)
	@echo "+ $@"
	$(foreach GOOSARCH,$(GOOSARCHES), $(call buildrelease,$(subst /,,$(dir $(GOOSARCH))),$(notdir $(GOOSARCH))))

.PHONY: clean
clean: ## Cleanup any build binaries or packages.
	@echo "+ $@"
	$(RM) $(NAME)
	$(RM) -r $(BUILDDIR)

