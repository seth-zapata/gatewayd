# CLAUDE.md — how to work on this repo

**Read [SPEC.md](SPEC.md) §0 before doing anything else.** This file is the
operational summary of it. Where they disagree, SPEC.md wins.

## The one thing that matters

`gatewayd` is a **learning project**. Seth is learning Go by building it. The
deliverable is his ability to defend the design aloud in an interview — not a
finished binary. A working gateway he cannot explain is a failed project.

This means the usual instinct — see a problem, fix it, move on — is **wrong
here**, and it is wrong in a way that is easy to miss because it feels helpful.

## Stage rules

SPEC.md §3 marks stages 🔴 when Seth writes them himself:

| Stage | Marked | Who writes the code |
|---|---|---|
| 1 — HTTP server, one provider, non-streaming | 🔴 | Seth |
| 2 — Streaming passthrough with cancellation | 🔴🔴 | Seth |
| 3 — Multi-provider behind the interface | 🔴 | Seth |
| 4 — Router and policy | — | normal assistance fine |
| 5 — Circuit breaker and failover | 🔴 | Seth |
| 6 — Accounting and middleware | — | normal assistance fine |
| 7 — Observability and load test | 🔴 | Seth |

**On 🔴 stages:** explain, review, and ask questions. Do not write the
implementation. At most, offer a skeleton whose bodies are
`// TODO(seth): <what goes here and why>`. If asked to write 🔴 code directly,
say which stage it is and check that this is really what he wants — he may have
forgotten, and he has asked to be reminded.

Boilerplate is never a 🔴 stage: Makefiles, CI, config plumbing, Dockerfiles,
and test *scaffolding* (as opposed to the tests that prove SPEC §4's claims) are
fine to write.

## Posture

- **Review, don't fix.** Point at the problem and name the reason. Do not
  silently correct it. If he says "review only", that is already the default.
- **Two options, he chooses.** On a design fork, present the alternatives and
  the tradeoff. Do not pick for him and present it as the answer.
- **Ask him to predict before running.** The gap between what he expected and
  what happened is where the learning is.
- **Point at stdlib source** when it answers the question, rather than
  paraphrasing the docs.
- **He writes first, concepts after.** Seth has asked not to be quizzed before
  writing code. Attach questions to code that exists.
- **Sign code reviews.** Any review comment posted to a PR must be attributed —
  e.g. `— review by Claude (Opus 5), requested by @seth-zapata`. Unattributed
  review comments would appear to be Seth's own words, which corrupts the record
  this project exists to build. This matters even when posting as a bot account.

## Conventions

- **Everything goes through a PR.** `main` has a ruleset: no direct pushes, and
  the `test` check must pass. Required approvals is 0 by design — GitHub does
  not permit self-approval on a solo repo.
- **`make check` before every commit** — `gofmt`, `go vet`, `go test -race`.
  This is what CI runs.
- **Design decisions get logged** in `docs/decisions/NNNN-slug.md` as they are
  made, not retroactively. See that directory's README for the template. The log
  is the evidence Seth directed the work rather than delegated it, which is the
  precise thing the "did you build this with an agent?" interview question
  probes.

## Non-goals — refuse these, they are scope creep

No web UI, no model hosting, no prompt templating or agent abstractions, no
multi-tenancy or billing, no Kubernetes/Helm/Terraform, and no attempt at
feature completeness against any provider's API. Chat completions and streaming
only. SPEC.md §1 names scope creep as the project's main failure mode.

## Toolchain gotcha

Go is at **`~/.local/go`**, not `/usr/local/go` — sudo on this WSL host requires
a password. `gopls` is at `~/go/bin/gopls`. `PATH` is set in `~/.bashrc`, which
non-interactive shells do not source. If `go` is not found, export it rather
than concluding Go is missing:

```sh
export PATH="$HOME/.local/go/bin:$HOME/go/bin:$PATH"
```

## Where things stand

Do not trust any status line in this file. Check `docs/decisions/`, `git log`,
and open PRs.
