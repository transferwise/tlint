SHELL := /bin/bash
NAME := tlint
PKG := github.com/transferwise/tlint

PREFIX?=$(shell pwd)
BUILDDIR := ${PREFIX}/cross

VERSION := $(shell cat VERSION.txt)
GIT_VERSION ?= $(shell git rev-parse HEAD)
CTIMEVAR=-X $(PKG)/GITCOMMIT=$(GITCOMMIT) -X $(PKG)/VERSION=$(VERSION)
GO_LDFLAGS=-ldflags "-w $(CTIMEVAR)"
GO_LDFLAGS_STATIC=-ldflags "-w $(CTIMEVAR) -extldflags -static"

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

.PHONY: clean
clean: ## Cleanup any build binaries or packages.
	@echo "+ $@"
	$(RM) $(NAME)
	$(RM) -r $(BUILDDIR)

