# 0001 — Repository scaffold and toolchain

- **Date:** 2026-09-01
- **Stage:** pre-Stage-1 (unmarked in SPEC.md §0 — normal assistance allowed)
- **Status:** decided

## Question
What exists in the repo before Stage 1 begins? SPEC.md §0 forbids the assisting
session from writing implementation code on red stages, but explicitly permits
"boilerplate, config plumbing, Makefiles, CI, and test scaffolding". The line
had to be drawn concretely.

## Options
1. **Toolchain and git only** — no directories, no layout. Maximum learning
   surface; Seth designs the package layout himself.
2. **Full scaffold, empty of logic** — module, package directories with only
   `doc.go` files, Makefile, CI. No types, no functions, no interfaces.
3. **Scaffold plus a compiling Stage 1 skeleton** — signatures present, every
   body a `// TODO(seth)`.

## Decision
Option 2. The repo contains a module, five package directories each holding
only a package comment, a Makefile, a CI workflow, and a `main` that prints a
version and exits non-zero. No `Provider` interface, no HTTP server, no types.

## Reasoning
Option 3 pre-decides the file and type layout, which is a real part of the
Stage 1–3 learning (SPEC §3 Stage 3 asks *why the interface lives in the
consumer's package* — a question that is spoiled if the scaffold has already
placed it). Option 1 spends Seth's time on `go mod init` and Makefile syntax,
which teach nothing about Go's concurrency or interface model.

Package *directories* were included despite being close to layout, because
their `doc.go` files carry the SPEC stage references and act as a map. They can
be deleted or renamed freely — nothing imports them.

## Consequences
- `make check` (fmt + vet + `test -race`) works from the first commit, so
  SPEC §4 criterion 5 is satisfied before there is anything to test.
- Go was installed to `~/.local/go` rather than `/usr/local/go` because sudo on
  this host requires a password. `PATH` is set in `~/.bashrc`; a backup of the
  original is at `~/.bashrc.bak-pre-go`.
- Module path is `github.com/seth-zapata/gatewayd`, matching the GitHub account
  used by glassbox, docsense, and options-radar. Changing it later means
  rewriting every import, so it was worth getting right before the first file.
