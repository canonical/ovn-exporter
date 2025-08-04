# Package directory
PKG_DIR := ./ovnexporter

##@ Development

.PHONY: build run run-debug fmt vet lint

build: ## Build the application binary
		cd $(PKG_DIR) && go build -o ../ovn-exporter ./cmd/*.go

run: ## Run the application
		cd $(PKG_DIR) && go run ./cmd/*.go

fmt: ## Format Go code
		cd $(PKG_DIR) && go fmt ./...

vet: ## Run go vet
		cd $(PKG_DIR) && go vet ./...

lint: fmt vet ## Run all linters (format and vet)

##@ Testing

.PHONY: test test-coverage mocks

test: ## Run all tests
		cd $(PKG_DIR) && go test ./...

test-coverage: ## Run tests with coverage report
		cd $(PKG_DIR) && go test -coverprofile=coverage.out ./...
		cd $(PKG_DIR) && go tool cover -html=coverage.out

mocks: ## Generate mock files using mockery
		mockery

##@ Help

.PHONY: help

help:  ## Display this help
		@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
