# gatewayd — see SPEC.md
#
# `make help` lists targets. Nothing here is clever on purpose; the Makefile is
# scaffolding, not part of the learning surface.

GO      ?= go
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS := -ldflags "-X main.version=$(VERSION)"
PKGS    := ./...

.DEFAULT_GOAL := help

.PHONY: help
help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build ./bin/gatewayd
	$(GO) build $(LDFLAGS) -o bin/gatewayd ./cmd/gatewayd

.PHONY: run
run: ## Run the daemon
	$(GO) run $(LDFLAGS) ./cmd/gatewayd

.PHONY: test
test: ## Run tests with the race detector (SPEC §4 criterion 5)
	$(GO) test -race -count=1 $(PKGS)

.PHONY: cover
cover: ## Run tests and open a coverage report
	$(GO) test -race -coverprofile=coverage.out $(PKGS)
	$(GO) tool cover -func=coverage.out | tail -1

.PHONY: bench
bench: ## Run benchmarks
	$(GO) test -run '^$$' -bench . -benchmem $(PKGS)

.PHONY: vet
vet: ## Run go vet
	$(GO) vet $(PKGS)

.PHONY: fmt
fmt: ## Format all Go source
	$(GO) fmt $(PKGS)

.PHONY: check
check: fmt vet test ## fmt + vet + race tests. Run this before every commit.

.PHONY: tidy
tidy: ## Tidy go.mod / go.sum
	$(GO) mod tidy

.PHONY: clean
clean: ## Remove build and profiling output
	rm -rf bin coverage.out *.prof *.pprof
