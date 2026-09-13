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

**Round 1 reviews the whole change. Round N>1 reviews only the delta**: TARGET is
`review-package <round N-1 head> <round N head>` plus an IN-SCOPE FILES line (files the fixes
touched, plus every file named in a round N-1 finding), and `check-findings` is pointed at that
round diff: a finding outside it is demoted to PRE-EXISTING mechanically (listed, never blocking,
never dropped). Pass `PRIOR_FINDINGS=@<ledger>`:
every earlier finding with its disposition (fixed <sha> / refuted <evidence> / accepted trade-off
<reason> / backlogged), never an open finding and never your claim that the code is now right. A
fix that rewrites a region a prior round CLEARED (rule of thumb: over 30 changed lines in such a
file) puts that file back in full scope for one round; that is the only way back to reviewed code.
An expensive oracle (a benchmark, a corpus run) runs at round 1 and at the terminal round only;
in between, CI_COMMAND is scoped to the area under review. The terminal run is never skipped: it
is the only pass that catches a regression review did not read. At the terminal round the auditor
may also be given the whole artifact once more (a full-scope pass), since real defects in
unchanged files are found by reading, not by diffing.

## 4. Verify the outputs mechanically, then read them

`scripts/check-findings <output.md> <diff-file>` fails when the JSON block is missing or invalid,
a finding lacks an evidence field, or a finding points at a file outside the diff. A failing
output goes back to the same reviewer once with the checker's message; a second failure is a
finding about the reviewer, recorded, and the run continues with what passed.

## 5. Third pass, before any fixing: the disprover, on what was not executed

Before anything is fixed, every BLOCKER and MAJOR that has NO observed output (the auditor's
findings, and any breaker finding whose `observed` field is reasoning rather than a run) goes
through one `review-breaker` with `templates/disprover.md` (`FINDINGS_FILE=`, `TARGET=`,
`CI_COMMAND=`). A breaker finding with an executed repro in the CI environment is already its own
disproof attempt and skips this pass; its fix is proven by the repro failing before and passing
after. Only UPHELD or executed findings can block; REFUTED, UNREPRODUCIBLE and MISCLASSIFIED ones
go to the ledger unedited. The published 63-83% kill rate is for reviewers that do not execute;
on executed findings it was near zero in two runs here, so the pass is spent where it pays. MINOR
findings skip the disprover and go straight to the backlog.

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

## 8. The stop rule: the gate decides, never the reviewer's verdict

`verdict: needs-rework` is advisory. The driver computes the landing decision from the JSON blocks
after every round. Name the oracle (benchmark, differential or property test, frozen corpus with
ground truth) and its pre-registered pass bar in CONTEXT before round 1; where one exists it decides
whether the change lands and review advises. A reviewer finding the oracle does not reproduce is a
request for a new oracle case, not a merge block.

BLOCKS landing: a red mechanical gate (build, tests, CI_COMMAND as CI runs it); the oracle below its
bar or regressed; any UPHELD BLOCKER; any UPHELD MAJOR at confidence >= 0.6 inside or provably reached
from the diff; any MAJOR corroborated by both reviewers; any unimplemented item of the frozen
contract that is checkable by construction (a contract sentence quantified over all inputs, "never
guesses", "any construct", is checked by the oracle only; a reviewer-invented instance outside the
oracle is an oracle-case request, listed under SPEC). A RULES FILE violation blocks once per rule;
the same rule again in the same class is one design finding, fixed at the rule or generator, never
per site. LISTED, never blocking, never silent: every MINOR and NIT; MAJOR below 0.6 and
single-source; anything first raised in round 3 that is not a BLOCKER; PRE-EXISTING; SPEC-unasked;
accepted trade-offs. Listed items go to one follow-up issue, one bullet per finding restating it
verbatim.

STOP AND LAND when a round leaves the blocking set empty. Round two is the normal exit; a round whose
upheld findings are all MINOR/NIT is convergence, not a reason for another round.
STOP AND ESCALATE to the owner, with the open findings in hand, when any of these fires:
- three rounds have run (the cap is a backstop; if it fires, that is an architecture signal,
  not a landing signal);
- a finding resurfaces unchanged after its fix;
- two consecutive rounds produced findings and none classified actionable (doubt theater: you are
  validating, not doubting; counted, not felt);
- a round's findings are all variations on a root cause already disposed (fix the rule, not the
  instance: the same class three times means a rulebook entry and a regenerated slice, not a
  fourth patch);
- the oracle has been green for two rounds while findings shrink in scope;
- fixable theater: three consecutive rounds whose upheld findings all land in files already
  patched in three earlier rounds (every finding real, cheap and irrelevant; the class, not the
  instance, is the defect: fix the rule and regenerate).
Never reduce finding volume by telling the reviewer the code is probably fine: reassuring context
costs up to 93 points of detection. Volume is reduced by the landing test, the severity
definitions, the disprover and the oracle, never by softening the contract.

The stop message, whichever stop fired, fills every field (`n/a` allowed, blank not):
LANDING DECISION land-clean | land-with-exceptions | hold; STOP REASON; ROUNDS k/3 with cost
(benchmark runs, reviewer runs); GATES (contract items, mechanical exit code, oracle value vs bar,
review upheld/raised with disprover kill rate); BLOCKING (must be empty to land); LISTED with the
reason each does not block; DISMISSED BY DISPROVER; PRE-EXISTING; SPEC; WHAT THIS DECISION DOES NOT
COVER (paths not executed, oracle splits not run, surfaces frozen out after round 1, and the
oracle's blind spots by name: every quantity it does not measure or measures on unlabelled data,
so "oracle green" is read at its true strength); NEXT ROUND WOULD COST.

**Goal and review go hand in hand.** A `/goal` that drives this skill names the exit as the
LANDING DECISION field of the stop message, never a reviewer verdict, never "until approved"; see
the goal-prompt skill. A goal written the old way re-prompts the session past every stop rule
here, because the goal outranks the skill.

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
