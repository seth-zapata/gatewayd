# gatewayd

An LLM gateway and model router in Go. One HTTP API in front of AWS Bedrock,
Anthropic, and OpenAI: routes by policy, streams the response back, accounts for
tokens and cost, and fails over when a provider degrades.

> **Status: scaffold.** No gateway exists yet. The module builds and CI is green,
> but `gatewayd` currently does nothing but print its version. See
> [SPEC.md](SPEC.md) §3 for the staged build plan and
> [docs/decisions/](docs/decisions/) for the design log.

## Why this exists

It is the public, inspectable version of a model access layer built for 30+
enterprise teams at AWS — work that is proprietary and therefore unprovable. Go
is the right language for it on the merits: a concurrent streaming proxy is what
the language is for.

## Claims this README will make when the project is done

Each is verifiable in under five minutes; none are true yet. From SPEC.md §4:

- [ ] Streaming cancellation is correct — a test disconnects mid-stream and
      asserts the *upstream* call was cancelled, not merely that the handler
      returned.
- [ ] No goroutine leak under load, demonstrated by a test.
- [ ] Failover is measured — observed error rate and recovery time from killing
      a provider mid-load.
- [ ] Published p50 / p95 / p99 under stated concurrency, load generator committed.
- [ ] `go test -race` clean, in CI on every push.

## Development

```sh
make help     # list targets
make check    # gofmt + go vet + go test -race   <- run before every commit
make build    # ./bin/gatewayd
```

Requires Go (see `go.mod` for the version).

## Non-goals

No web UI, no model hosting, no prompt templating or agent abstractions, no
multi-tenancy or billing, no Kubernetes manifests, and no attempt at feature
completeness against any provider's API. Chat completions and streaming only.
See SPEC.md §1 — scope creep is the named failure mode.
