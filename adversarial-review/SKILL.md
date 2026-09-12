---
name: adversarial-review
description: "The only review method here: two independent reviewers with different methods (auditor reads, breaker executes) over a diff, plan, or artifact, evidence schema per finding, findings merged by severity and confidence. Required for security work. Trigger: /adversarial-review"
---

# Adversarial review (Claude driver)

Templates are host-neutral files in `templates/` (shared with the Codex driver at
`~/.codex/skills/adversarial-review/`). This file is only the Claude launch procedure.

## 0. Choose the depth

Full method (auditor + breaker) for anything security-relevant, production-facing, touching auth,
data, money, or a defect class that has repeated. **Light option: auditor only**, for a change that
is small, low-risk, and none of the above; skip step 3's breaker, skip the agreement map, and record
"reviewed by adversarial-review (light)" in the ledger. On Codex the built-in `codex review` alone is
an acceptable light option too. The method is never weakened; only the depth is chosen.

## 1. Package the target

Never hand a reviewer your session history. `scripts/review-package <base> [head]` writes the
commit list, `--stat` and `git diff -U10` to one file and prints its path. For a doc or plan,
the path of the artifact is the target. A 500-line artifact gets decomposed before review.

## 2. Fill the templates

`scripts/fill-template templates/auditor.md TARGET=<path> CONTEXT="..." SPEC_TEXT=@<file> RULES_FILE=<CLAUDE.md path>`
and the same for `templates/breaker.md` with `CI_COMMAND="..."` added (the exact command CI runs,
with container/image, env file and toolchain version; the project CLAUDE.md carries it).

**Hand over the artifact and the contract, never your claim.** CONTEXT says what the artifact is
supposed to satisfy, not whether you think it does. A reviewer given your conclusion returns it.

## 3. Launch two agents in parallel, same message

- `subagent_type: review-auditor`, prompt = filled auditor template. Tools: Read/Grep/Glob only.
- `subagent_type: review-breaker`, prompt = filled breaker template, `isolation: "worktree"`.
  Tools: Read/Grep/Glob/Bash; the worker-fence hook refuses push and merge inside it.

Effort is set by the agent definition (Opus 5, high); the templates carry no effort line.
Neither reviewer sees the other's findings. Do not review inline yourself.

For an external reviewer (Grok, Muse), hand the same filled template as the spec; the tool
restriction does not reach them, so the fence there is prose only, and `check-findings` is the
only gate.

## 4. Verify the outputs mechanically, then read them

`scripts/check-findings <output.md> <diff-file>` fails when the JSON block is missing or invalid,
a finding lacks an evidence field, or a finding points at a file outside the diff. A failing
output goes back to the same reviewer once with the checker's message; a second failure is a
finding about the reviewer, recorded, and the run continues with what passed.

## 5. Optional third pass: the disprover

When A and B together return more than about ten findings, or you cannot verify the
BLOCKER/MAJOR ones yourself: one `review-breaker` with `templates/disprover.md`
(`FINDINGS_FILE=`, `TARGET=`, `CI_COMMAND=`). Only UPHELD findings continue.

## 6. Merge and present

Dedup by root cause. A finding surfaced by BOTH is corroborated: near-certain. Weigh single-source
findings by their confidence field. Verify every BLOCKER/MAJOR yourself (through a subagent
re-run) before acting. Present three things separately:
- **Ranked findings**: the standards axis, corroborated first, severity then confidence.
- **Spec axis**: asked / delivered / unasked with the request quoted. Kept out of the ranking:
  "does the wrong thing well" and "does the right thing badly" are different problems.
- **Agreement map**: per root cause, found by both / auditor only / breaker only, and for each
  divergence whether it is a topic the other never covered (expected) or the same evidence read
  two ways (adjudicate it and say which way you went).
Carry both DISMISSED lists and the PRE-EXISTING lists through unedited, collapsed at the end.

## 7. Classify each finding, first match wins

1. **Contract misread**: flagged because CONTEXT was unclear or incomplete. Fix the contract first,
   re-classify next pass.
2. **Valid and actionable**: change it, re-verify.
3. **Valid trade-off**: real, but fixing costs more than accepting. Document the trade-off so the
   owner sees a choice, not an inheritance.
4. **Noise**: correct under context the reviewer lacked. Would adding it to CONTEXT have prevented
   the flag? Then that is a contract fix for next time.

Presumptive blockers, always surfaced with the simpler alternative: a refactor that relocates
complexity; a file pushed past its size boundary with no decomposition; feature logic in a shared
module; a near-duplicate of a canonical helper; a silent fallback hiding an unclear invariant.

## 8. Doubt theater, the checkable signal

Two or more passes with substantive findings and zero classified actionable: you are validating,
not doubting. Stop, say so, escalate. Count the classifications; this is a predicate, not a feeling.

## 9. Afterwards

Verify each accepted finding against the codebase before implementing; clarify unclear items before
implementing any; land every finding in a named bucket (fixed / trade-off documented / noise with
contract fix). Never resolve a finding by weakening the check that produced it. Record in the merge
ledger: "reviewed by adversarial-review, verdict files <paths>".

## Codex breaker and OpenAI's cybersecurity classifier

A Codex breaker turn is scanned by OpenAI's classifier; a session that writes executing payloads
(`$(id)`, `__import__`, marker-file side effects) or narrates in attack vocabulary is cut with
`turn.failed: "flagged for possible cybersecurity risk"` and its report is lost (observed
2026-09-13, three runs over a shell-heavy verification suite). The breaker template therefore carries an
authorization paragraph, verification vocabulary, a rule that splicing is proven by a parse error
or an altered string and never by an executing value, and a running `.breaker/progress.md`. When a
run is still cut: read `.breaker/progress.md` and the `*.events.jsonl` command outputs for the
evidence it produced, rerun once, and record the cut in the ledger; it is not a finding about the
code. Scope CI_COMMAND to the area under review: a suite row elsewhere that needs a local socket
or a package the sandbox lacks reads as a lock and stops the review.
