# SPEC — `gatewayd`: an LLM gateway and model router in Go

**Handoff document.** Written 2026-09-01 for a separate Claude Code session working with Seth
Zapata. Read the whole thing before writing any code, including §0.

---

## §0 — 🔴 READ FIRST: this is a learning project, not a delivery project

**Seth is learning Go through this build. The goal is his understanding, not a finished binary.**
A working gateway he cannot explain is a failed project; a half-finished one he can defend line
by line in an interview is a successful one.

**Therefore, for the assisting session:**

| Do | Do not |
|---|---|
| Explain tradeoffs, and name the alternatives you rejected | Write implementation code for the 🔴 stages below |
| Answer "why does Go do it this way" at depth | Hand over a finished file and move on |
| Review code he wrote and point at what is unidiomatic, with the reason | Silently fix things |
| Propose two approaches and make him choose | Choose for him |
| Ask him to predict output *before* running it | Run it first and explain after |
| Point at the stdlib source when it answers the question | Paraphrase the docs |

**When he asks you to write code, ask whether this is a 🔴 stage first.** On 🔴 stages, offer a
skeleton with the interesting parts left as `// TODO(seth): ...` and a description of what goes
there. On unmarked stages, normal assistance is fine — boilerplate, config plumbing, Makefiles,
CI, and test scaffolding are not where the learning is.

**Keep the conversation history.** Seth's differentiator across three prior projects is that his
claims are checkable. A committed transcript of the design questions he asked is direct evidence
he *directed* the work rather than delegated it — which is the exact thing the "did you build
this with an agent?" interview question is probing. This is also why the AI-assistance tension he
raised resolves cleanly: **AI as tutor and reviewer is a strength to show; AI as author would
destroy the thing the project exists to prove.**

---

## §1 — What it is

A single HTTP API in front of multiple LLM providers (AWS Bedrock, Anthropic, OpenAI), which
routes each request to a provider by policy, streams the response back, accounts for tokens and
cost, and fails over when a provider degrades.

**Why this project:** it is the public, inspectable version of the model access layer Seth built
at AWS for 30+ enterprise teams — work that is currently proprietary and unprovable. It is also
genuinely Go-shaped: a concurrent streaming proxy is what the language exists for, so the choice
of Go is defensible on the merits rather than performative.

### Non-goals — say no to these explicitly
- ❌ A web UI. This is a daemon. Ship a CLI and metrics.
- ❌ Its own model hosting or inference.
- ❌ Prompt templating, chains, or agent abstractions. Not a framework.
- ❌ Multi-tenancy, billing, or auth beyond a static API key.
- ❌ Kubernetes manifests, Helm charts, Terraform. A Dockerfile is enough.
- ❌ Feature completeness against any provider's full API. Chat completions and streaming only.

Scope creep is the main failure mode here. Every one of the above is a plausible "while we're at
it" that would cost weeks and prove nothing new.

---

## §2 — Architecture, at the level that matters

```
        client
          │  POST /v1/chat  (SSE stream back)
          ▼
   ┌──────────────────┐
   │  HTTP handler    │  request validation, API key, request ID
   └────────┬─────────┘
            │
   ┌────────▼─────────┐
   │  Router          │  policy → picks a Provider
   │  (policy engine) │  rules first; adaptive later if at all
   └────────┬─────────┘
            │
   ┌────────▼─────────┐      ┌───────────────────┐
   │  Provider iface  │◄─────┤ Breaker (per prov)│  open/half-open/closed
   └────────┬─────────┘      └───────────────────┘
            │
   ┌────────▼──────────────────────────┐
   │ bedrock.go │ anthropic.go │ openai.go │   each implements Provider
   └────────┬──────────────────────────┘
            │  streaming chunks
   ┌────────▼─────────┐
   │  Accounting      │  tokens in/out, cost, latency per stage
   └────────┬─────────┘
            ▼
      metrics + structured logs
```

**The one interface that matters:**

```go
type Provider interface {
    Name() string
    Stream(ctx context.Context, req Request) (<-chan Chunk, error)
}
```

Keep it that small. If it grows past three methods, something is wrong — push the extra
behaviour into a wrapper type instead. "Accept interfaces, return structs" is the idiom, and the
reason it works is §3 Stage 3.

---

## §3 — Staged build. Each stage exists to teach one thing.

🔴 = **Seth writes this himself.** Assisting session explains and reviews only.

### Stage 1 — HTTP server, one provider, non-streaming 🔴
Get a request to Anthropic and back. Nothing clever.

**Teaches:** `net/http` handlers, `http.Client` with a real timeout, `encoding/json` with struct
tags, and Go's explicit `if err != nil` return style.

**Questions he should be able to answer before moving on:**
- Why does Go return errors as values instead of throwing? What does that buy, and what does it
  cost in verbosity? When does `errors.Is` / `errors.As` matter?
- What is wrong with `http.DefaultClient` in a server? (timeouts, connection pooling)
- Why do struct tags exist rather than a naming convention?

### Stage 2 — Streaming passthrough with correct cancellation 🔴🔴
**The hardest and most interesting stage. Do not rush it.** SSE from provider → client, and when
the client disconnects mid-stream, the upstream request must actually be cancelled.

**Teaches:** `context.Context` at depth, `http.Flusher`, `bufio.Scanner` vs `io.Copy`, and
goroutine lifetime.

**Questions:**
- What does `context.Context` actually propagate, and what happens if you accept a `ctx` and
  never pass it down?
- How do you know the client hung up? What does `r.Context().Done()` fire on?
- **Where is the goroutine leak in a naive implementation?** Write one deliberately, then find it
  with `go test -race` and a leak check. This is the single best thing in the project.
- Why `bufio.Scanner` and what is its default buffer limit? (this bites on long SSE lines)

### Stage 3 — Multi-provider behind the interface 🔴
Add Bedrock and OpenAI. Same `Provider` interface, three implementations.

**Teaches:** implicit interface satisfaction — the thing that most surprises people arriving from
Java.

**Questions:**
- Nothing declares `implements Provider`. Why did Go choose structural typing, and what does it
  enable that Java's explicit `implements` does not? (hint: you can satisfy an interface you did
  not know existed, including one defined in *your* package for *their* type)
- Why is the interface defined in the *consumer's* package rather than alongside the
  implementations?
- Where would a `switch p := p.(type)` be a design smell here?

### Stage 4 — Router and policy
Rules-based routing: by model name, by cost ceiling, by explicit override header. Adaptive
routing is a *stretch goal only* — do not start here.

**Teaches:** ordinary Go composition. Not much new, deliberately — a breather stage.
Normal AI assistance is fine here.

### Stage 5 — Circuit breaker and failover 🔴
Per-provider breaker: closed → open → half-open. On open, route elsewhere.

**Teaches:** shared mutable state under concurrency, and **when a channel is the wrong tool.**

**Questions:**
- A breaker is a small state machine touched by many goroutines. Channel or `sync.Mutex`? Defend
  the answer. (Most people reach for a channel here and are wrong — "share memory by
  communicating" is a default, not a law.)
- Run `go test -race`. What does it actually detect, and what can it *not* detect?
- What is the half-open probe policy, and what happens if two goroutines probe at once?

### Stage 6 — Accounting and middleware
Tokens in/out, cost per request, per-stage latency. Implemented as `http.Handler` wrapping.

**Teaches:** the middleware pattern via handler composition, `sync/atomic` vs mutex for counters.

**Questions:**
- Why does Go's middleware pattern need no framework? What is `func(http.Handler) http.Handler`
  actually doing?
- Counters: `atomic.Int64` or a mutex-guarded struct? What changes the answer?

### Stage 7 — Observability and the load test 🔴
Prometheus metrics (or `expvar`), structured logs with request IDs, and a load test that
publishes **p50 / p95 / p99 under N concurrent streams**.

**Teaches:** Go's built-in tooling, which is a genuine differentiator versus Python — `go test
-bench`, `pprof`, `go test -race` as a normal part of the workflow.

**Questions:**
- Take a `pprof` goroutine profile under load. How many goroutines per in-flight request, and is
  that the number you expected?
- What does a flat p50 with a climbing p99 tell you? Where would you look first?

---

## §4 — Success criteria

The project is done when the README can make these claims and a reader can verify each in under
five minutes:

1. **Streaming cancellation is correct.** A test that disconnects mid-stream and asserts the
   upstream call was cancelled — not merely that the handler returned.
2. **No goroutine leak under load.** Goroutine count returns to baseline after N requests,
   demonstrated by a test, not asserted in prose.
3. **Failover is measured.** Kill a provider mid-load; publish the observed error rate and
   recovery time, not a description of the design.
4. **Published percentiles.** p50/p95/p99 under stated concurrency, with the load generator
   committed so the numbers are reproducible.
5. **`go test -race` clean**, and it runs in CI on every push.
6. **A negative result, if one appears.** Seth's signature across DocSense and Glassbox is
   publishing the measurement that disagreed with the design. If routing-by-latency turns out not
   to beat round-robin, say so with the data. **Do not manufacture one** — only report it if it
   is real.

---

## §5 — Resume placement

**Replaces Options Radar** (2024–2025, oldest and weakest of the three). It inherits that
project's best story — fault-tolerant multi-provider reconciliation and graceful degradation —
and adds Go, gateway semantics, and measured concurrency.

**Glassbox and DocSense stay.** Do not touch them.

Only swap it in once criteria 1, 2 and 4 in §4 hold. A half-built gateway on the resume is worse
than Options Radar, which is finished and defensible.

---

## §6 — Pace, and what "done" means

Stages 1–3 are the real Go education; 4–7 are consolidation. If the stack runs out of time,
**a rigorously understood Stage 1–3 beats a rushed Stage 1–7.**

Target: weeks, not days. Seth's stated intent is to go slowly and understand the tradeoffs, and
that is correct here — the entire value of this project is that he can defend it aloud in a design
conversation, which is precisely the format his Apple panel identified as the weak point.

**Interview payoff, stated plainly:** by the end he should be able to hold a twenty-minute
conversation about context propagation, goroutine lifetime, why the breaker uses a mutex, and
what the p99 tail told him. That conversation is the actual deliverable. The binary is the
evidence that it happened.
