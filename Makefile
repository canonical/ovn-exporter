# Package directory
PKG_DIR := ./ovn-exporter

ALL_TESTS := $(wildcard tests/*.bats)
OVN_EXPORTER_SNAP := ovn-exporter.snap
OVN_EXPORTER_SOURCES := $(shell find ovn-exporter/ -type f -name "*.go")
SNAP_SOURCES := $(shell find snap/ -type f)

##@ Snap

$(OVN_EXPORTER_SNAP): $(OVN_EXPORTER_SOURCES) $(SNAP_SOURCES) ## Build the application snap
		SNAPCRAFT_ENABLE_EXPERIMENTAL_EXTENSIONS=1 snapcraft pack -o $(OVN_EXPORTER_SNAP)

build: $(OVN_EXPORTER_SNAP) ## Build the application snap

##@ Development

.PHONY: go-build run run-debug fmt vet check-lint lint shfmt shfmt-fix

go-build: ## Build the application binary
		cd $(PKG_DIR) && go build -o ../ovnexporter ./cmd/*.go

run: ## Run the application
		cd $(PKG_DIR) && go run ./cmd/*.go

fmt: ## Format Go code
		cd $(PKG_DIR) && go fmt ./...

vet: ## Run go vet
		cd $(PKG_DIR) && go vet ./...

shfmt:  ## Check shell format
		test $$(shfmt -l -s ./snap | wc -l) -eq 0 || (echo "FAILED: Files need formatting" && shfmt -l -s ./snap && exit 1)

shfmt-fix:  ## Fix shell format
		shfmt -w -l -s ./snap

check-tabs:  ## Check tabs
	grep -lrP "\t" tests/ && exit 1 || exit 0

check-lint: check-tabs shfmt  ## Run shell linters
	find tests/ \
		-type f \
		-not -name \*.yaml \
		-not -name \*.swp \
		-not -name \*.conf\
		| xargs shellcheck --severity=warning && echo Success!

check-lint-go: fmt vet ## Run Go linters (format and vet)

##@ Testing

.PHONY: test test-coverage mocks check-system $(ALL_TESTS)

test: ## Run all tests
		cd $(PKG_DIR) && go test ./...

test-coverage: ## Run tests with coverage report
		cd $(PKG_DIR) && go test -coverprofile=coverage.out ./...
		cd $(PKG_DIR) && go tool cover -html=coverage.out

mocks: ## Generate mock files using mockery
		mockery

$(ALL_TESTS): go-build
	echo "Running functional test $@";  \
	$(CURDIR)/microovn/.bats/bats-core/bin/bats $@

check-system: $(ALL_TESTS)  ## Run functional test

##@ Help

.PHONY: help

help:  ## Display this help
		@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
