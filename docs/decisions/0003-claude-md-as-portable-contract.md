# 0003 — CLAUDE.md as the portable form of the §0 contract

- **Date:** 2026-09-02
- **Stage:** pre-Stage-1 (unmarked — config plumbing)
- **Status:** decided

## Question
SPEC.md §0 binds the *assisting session* not to write code for 🔴 stages. But a
session is not durable: a new conversation next month, or a `claude[bot]` run
triggered from a pull request comment, starts with no memory of this one. What
makes the contract survive?

The question surfaced while considering `anthropics/claude-code-action`, which
runs a fresh Claude Code session inside a GitHub Actions runner. Such a session
sees the checked-out repo, the PR diff, the comment thread, and `CLAUDE.md` —
and nothing else.

## Options
1. **Rely on SPEC.md alone.** It is committed, so any session *could* read it.
   But nothing guarantees a session opens it before acting, and §0 is 1 of 6
   sections in a 300-line document.
2. **Rely on the assistant's per-machine memory.** Already written, and already
   insufficient: it lives at `~/.claude/projects/` on one WSL host, so it is
   invisible to a fresh clone and to any CI-triggered run.
3. **A `CLAUDE.md` at the repo root**, loaded automatically by every Claude Code
   session including CI-triggered ones.

## Decision
Option 3. `CLAUDE.md` restates §0 operationally — the 🔴 stage table, the
review posture, the PR and decision-log conventions, the non-goals, and the
`~/.local/go` toolchain gotcha. It defers to SPEC.md explicitly where the two
disagree, so there is one source of truth and one summary, not two specs.

## Reasoning
The failure this prevents is concrete and likely: a fresh reviewer reads a
Stage 2 pull request, sees a goroutine leak, and helpfully rewrites the
function. That is a *correct* review action under ordinary norms and a direct
violation of the thing this project exists to prove. The contract has to travel
with the repository, because the reviewer will not always be this session.

It also settles the division of labour that made the GitHub App attractive:
- **Interactive session = tutor.** Continuity is its value.
- **A PR reviewer = fresh eyes.** Contamination is a real review hazard — a
  reviewer who watched the code get written reads past ambiguity because they
  know what was meant. Statelessness is a feature in that role.

`CLAUDE.md` is what makes the second role safe.

## Consequences
- Adding the GitHub App later is now a low-risk change; the guardrail is
  already committed. The decision to install it is deliberately deferred until
  there is a real pull request to review.
- The file must be kept honest. It ends by telling readers not to trust any
  status line in it and to check `docs/decisions/`, `git log`, and open PRs —
  a stale "we are on Stage 3" line would be worse than no line.
- The commit-status merge gate (a required `claude-review` context that only the
  assistant could set green) was considered and **rejected as over-engineering**.
  Statuses are per-SHA, so every push — including a typo fix — would have
  invalidated the approval and blocked the merge until a re-review. That is a
  lot of friction to buy discipline on a solo repository that has not yet
  written a line of Go.
