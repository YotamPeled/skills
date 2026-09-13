# skills

Reusable skills for [Claude Code](https://claude.com/claude-code) and
[Codex](https://github.com/openai/codex). A skill is a folder with a `SKILL.md` the agent loads
when the task matches, or when you type `/<name>`.

## Install

Clone anywhere, then symlink the skills you want.

```bash
git clone https://github.com/YotamPeled/skills.git ~/src/skills

# Claude Code
ln -s ~/src/skills/adversarial-review ~/.claude/skills/adversarial-review
ln -s ~/src/skills/goal-prompt        ~/.claude/skills/goal-prompt
ln -s ~/src/skills/adversarial-review/agents/review-auditor.md ~/.claude/agents/
ln -s ~/src/skills/adversarial-review/agents/review-breaker.md ~/.claude/agents/

# Codex
ln -s ~/src/skills/adversarial-review/codex ~/.codex/skills/adversarial-review
ln -s ~/src/skills/goal-prompt              ~/.codex/skills/goal-prompt
```

`~/.claude/skills/` is available in every project; `<project>/.claude/skills/` in that project
only. Codex reads `~/.codex/skills/`.

## Skills

### `adversarial-review`

Two independent reviewers over a diff, a plan, or any artifact, run in parallel and merged:

- **the auditor** verifies by READING: does the artifact's story match the code? Callers that
  supposedly don't exist, contracts that move, migrations that break a live path, drift from the
  spec. No write tools by construction.
- **the breaker** verifies by EXECUTING, in a scratch worktree with no network: runs the suite the
  way CI runs it, feeds adverse input, races concurrent calls, stops a dependency mid-operation.
  Every finding ships with the exact sequence and the observed output.

The pair differs in *method*, not topic. Findings carry severity (BLOCKER / MAJOR / MINOR),
confidence, `file:line`, scenario, repro, observed output, blast radius and a one-sentence fix;
`scripts/check-findings` rejects a report that lacks any of them or names a file outside the
diff. What both reviewers surface independently is near-certain. Each also reports what it
checked and cleared, which separates "verified safe" from "never looked at".

Layout: `SKILL.md` is the Claude driver (two subagents, `agents/` holds their definitions);
`codex/` is the Codex driver (two `codex exec` sessions, `scripts/run-auditor.sh` and
`scripts/run-breaker.sh`); `templates/` and `scripts/` are shared. A third pass, the disprover,
re-tests every BLOCKER/MAJOR that has no executed repro before anything is fixed.

**The gate decides, never the reviewer's verdict.** Round 1 reviews the whole change; later
rounds review only the delta plus a ledger of prior dispositions the reviewers may not re-raise.
Landing is computed from the findings JSON and the oracle (benchmark, test suite, corpus) named
before round 1: red CI, oracle under its bar, an upheld BLOCKER, an upheld MAJOR inside the diff,
or an unimplemented contract item blocks; everything else is listed in one follow-up issue. The
run stops when the blocking set is empty, and escalates at three rounds, on a finding that
resurfaces after its fix, on a repeated root cause, or on three rounds that only patch
already-patched files. Lesson behind it: a loop keyed on "until the reviewers approve" ran 25
rounds and 12 hours on one proof of concept and was stopped by hand; reviewers always return new,
real, shrinking findings, so convergence has to be a property of the gate.

**Goal and review go hand in hand.** A `/goal` that drives a review loop must exit on the
review's LANDING DECISION line, never on a reviewer verdict: the goal outranks the skill, so a goal
written as "until approved" re-prompts the session past every stop rule. The `goal-prompt`
checklist rejects that wording and requires the oracle, its bar, a round cap and a progress-file
round counter in the goal text.

Track record: on one microservice the auditor caught a plan built on a false premise and a
migration that would have broken a live admin path; the breaker caught an endpoint that 500'd
under ordinary concurrency, non-atomic account deletion that resurrected deleted accounts, a
rate limit that throttled the whole site as one bucket, and a config that would have
crashlooped in production. On a shell-heavy verification suite, one round returned 21 real
findings (13 by reading, 8 by execution, 3 found by both).

Cost: two long reviewer sessions per invocation. Worth it before a merge, overkill for a
one-line change; the skill has a light option (auditor only).

Note for Codex: a breaker session that writes executing payloads or narrates in attack
vocabulary gets cut by OpenAI's cybersecurity classifier and its report is lost. The breaker
template therefore proves a splice by a parse error, never by an executing value, and keeps a
running `.breaker/progress.md`; see the Codex `SKILL.md` for the rest.

### `goal-prompt`

How to write a correct `/goal` for Codex or Claude Code: the official template and its six
slots, the character cap, what changes when a goal is active, and a worked example
(`examples/overnight-board-goal.md`).
