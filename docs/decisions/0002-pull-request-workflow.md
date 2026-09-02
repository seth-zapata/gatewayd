# 0002 — Pull request workflow and branch protection

- **Date:** 2026-09-01
- **Stage:** pre-Stage-1 (unmarked — process, not code)
- **Status:** decided

## Question
How do changes reach `main`? Seth asked for a PR-based flow specifically so CI
runs before anything merges, rather than after.

## Options
1. **Push straight to `main`, CI runs after the fact.** Zero friction. CI
   becomes a notification that main is broken rather than a gate.
2. **PR convention, unenforced.** Open PRs by habit; nothing stops a direct
   push on a tired evening.
3. **PR required, enforced by a GitHub ruleset**, with the `test` check as a
   required status.

## Decision
Option 3. A ruleset on `~DEFAULT_BRANCH` with four rules: `pull_request`
(0 required approvals), `required_status_checks` (`test`, strict), `deletion`,
and `non_fast_forward`. Verified by attempting a direct push to `main`, which
was rejected with "push declined due to repository rule violations".

Repo is public, which is what makes this free — GitHub gates branch protection
on private repos behind a paid plan.

## Reasoning
Required approvals are set to **0**, not 1. GitHub does not permit approving
your own pull request, so on a solo repo a requirement of 1 is not a quality bar
— it is a lock with no key. The gate that carries real weight here is the green
`test` check, which includes `go test -race` (SPEC §4 criterion 5).

`strict_required_status_checks_policy` is on, so a branch must be current with
`main` before merging. On a solo repo this rarely bites, and it means CI results
always describe the code that actually lands.

No bypass actors were configured, so the rule applies to the repo owner too.
That is the point. If CI ever wedges, the ruleset can be disabled in repo
settings — a deliberate act, which is the right amount of friction.

## Consequences
- Every change, including scaffolding, needs a branch and a PR. This is more
  ceremony than a solo project usually justifies, and it is wanted here: the PR
  list becomes a second readable record of how the project was built, alongside
  `docs/decisions/`.
- PRs are the natural review surface for the 🔴 stages. The template asks
  directly whether a change was a red stage and who wrote it.
- `main` can no longer be force-pushed or deleted, so history is append-only.
