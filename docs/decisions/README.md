# Decision log

One file per design decision, named `NNNN-short-slug.md`, numbered in the order
decided. Each records the question, the options considered, the choice, and the
reasoning — including options rejected and why.

**Why this exists.** SPEC.md §0: the claim this project makes is that Seth
*directed* the work rather than delegated it. A decision log is the checkable
form of that claim. An interviewer reading `0003-stream-error-propagation.md`
can see the alternatives were weighed, not stumbled into.

Write the entry *when the decision is made*, not retroactively. A log
reconstructed after the fact is worth much less and is usually obvious.

## Template

```markdown
# NNNN — <the decision, as a noun phrase>

- **Date:** YYYY-MM-DD
- **Stage:** SPEC.md §3 Stage N
- **Status:** decided | superseded by NNNN | revisited

## Question
What had to be decided, and what forced the decision now.

## Options
1. **<option>** — what it buys, what it costs.
2. **<option>** — ...

## Decision
What was chosen.

## Reasoning
Why. Name the option rejected and the specific reason it lost.

## Consequences
What this makes easy, what it makes hard, and what would make us revisit it.
```
