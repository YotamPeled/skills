---
name: goal-prompt
description: Write a correct `/goal` for Codex or Claude Code — the official template and six slots, the 4,000-character cap, the mechanics that change the wording (Codex marks blocked only after three turns; Claude's evaluator reads only the transcript), when /goal beats /loop, and a checklist. Use when writing or reviewing a /goal, or turning a spec into one.
---
# Writing a Codex `/goal`

A goal is persisted thread state: Codex keeps starting new turns toward it whenever the thread is
idle, until the model proves it complete or the user pauses or clears it. The objective is
re-rendered into every continuation turn, so it is read by a model that may have compacted away
everything else. Write it as a contract, not a briefing. Sources: OpenAI's cookbook "Using Goals
in Codex", the "Follow a goal" page, the CLI command reference, and the openai/codex repository
(the continuation prompt template and PRs #18075–#18077, #20523, #22045).

## The template (official)

```
/goal <desired end state> verified by <specific evidence> while preserving <constraints>.
Use <allowed inputs, tools, or boundaries>. Between iterations, <how to choose the next action>.
If blocked or no valid paths remain, <what to report and what would unlock progress>.
```

Six slots, all of them, in this order:

1. **Outcome** — what is true when done. One objective, one stopping condition. Not "improve X";
   "make the checkout suite pass on this branch without changing public API behavior".
2. **Verification surface** — the commands, artifacts or files that prove it. Prefer the
   user-visible fact over the internal claim; an event ("a review happened") is not evidence,
   a file it wrote is.
3. **Constraints** — what must not regress. These belong in the goal; there is no official
   advice to move them to project instructions.
4. **Boundaries** — the directory, files, tools, resources it may use; the files it must read
   first (a spec, a plan, a state file).
5. **Iteration policy** — how it chooses the next action after each attempt: work items in
   order, keep a short progress log, record what changed and what the evidence showed.
6. **Blocked stop** — what it reports when no defensible path remains, and what input would
   unlock it.

## Limits and format

- **At most 4,000 characters**, non-empty. Longer instructions go in a file the goal points at;
  the TUI spills an oversized objective to a file by itself, but write it short on purpose.
- One paragraph. Multi-line is not documented; every official example is a single paragraph.
- No token budget from the slash command; do not ask for one unless the owner did.
- Set it from the composer: `/goal <objective>`. `/goal` shows it, `/goal edit`, `/goal pause`,
  `/goal resume`, `/goal clear`. Never hand a `/goal` line through `codex queue` — not a
  documented path, and a queued message also blocks continuation (next section).

## Mechanics that change the wording

- **Continuation fires only when the thread is idle, no input is queued, no other work is
  pending.** So nobody may queue messages at a window while its goal runs; steer by editing the
  goal, not by sending one-off instructions.
- **"Blocked" has a threshold.** The continuation prompt tells the model: never mark blocked
  the first time a blocker appears; only after the same blocker stopped it on three
  consecutive goal turns; never because work is hard, slow or unclear. Write the blocked-stop
  slot to match: report the blocker, keep the goal active, keep working on what does not
  depend on it. A per-item "three tries then move on" rule must say it is progress, not a
  blocked goal, or the two three-counts collide.
- **Completion is an audit, not a feeling.** The model must prove every explicit requirement,
  numbered item, named artifact, command and gate against current state, and may not shrink
  the objective to what already exists. So enumerate the items and name the evidence per item.
- **Budget exhaustion is a soft stop, not completion.** Nothing to write; just do not ask it to
  "finish by" a time.
- **No time pressure.** OpenAI removed elapsed-time from its own prompt after seeing the model
  shortcut work when nervous about time. Leave out "by 8am", "tonight", "quickly".
- **Name what may not run.** If a check can be unavailable or flaky (a review by another
  session, a container rebuild, a benchmark), say what to do then: record why, treat the item
  as unverified, continue on independent items.
- **Interrupts pause the goal; resuming the thread reactivates it.** Plan mode never
  continues. Compaction is handled by the runtime (the objective is re-rendered, not
  summarized), but a concrete, measurable objective is what survives it in practice.
- **Not for small things.** A one-line edit, an explanation, a review, a single answer, or a
  loose list of unrelated work is a prompt, not a goal.

## Authoring workflow

1. Describe the work in plain language; put the long detail (spec, plan, done-when list) in a
   file. 2. Draft the goal in the template — or ask Codex to draft it from the description.
3. Tighten the outcome, the evidence per item, the constraints and the blocked-stop. 4. Check
the list below. 5. Paste into the composer.

## Checklist

- [ ] One objective, one stopping condition, provable by running something
- [ ] Every item the audit will check is enumerated, each with its evidence
- [ ] Evidence is inspectable (files, command output), not events
- [ ] Constraints stated; boundaries stated; files to read first named
- [ ] Iteration policy names the state/progress file and the order of work
- [ ] Blocked-stop reports and keeps going; "blocked" only after three consecutive turns
- [ ] Anything that may not run has a stated fallback
- [ ] No clock, no deadline, no "quickly"
- [ ] Settled decisions marked as closed
- [ ] Under 4,000 characters, one paragraph
- [ ] Every inner loop (review, retry, re-run) has a round cap and a stop rule
- [ ] A review loop exits on the review skill's LANDING DECISION, never on a reviewer verdict;
      a goal that says "until approved" / "until the reviewers pass it" is rejected here
- [ ] The oracle (benchmark, test suite, corpus) and its pass bar are named in the goal, and the
      round counter lives in the progress file so the cap is checkable from outside

## Claude Code's `/goal` — same shape, different judge

Claude Code (2.1.139+) has `/goal <condition>` too. Official page: https://code.claude.com/docs/en/goal.
The template and checklist above apply, with these differences:

- **The judge is a separate small model reading the transcript.** After every turn it returns
  met / not yet / impossible. It runs no commands and reads no files, so the condition must be
  something Claude's own output demonstrates: "`npm test` exits 0", "`git status` is clean",
  "the file count under src/ is under 20". A condition only a human could see is never met.
- **Not yet + reason steers the next turn**, so the condition doubles as the iteration policy.
- **Bound it in the condition**: "… or stop after 20 turns". Nothing else caps it.
- **Unattended needs auto mode**; a goal does not change the permission mode.
- **It clears itself** when met, when judged impossible, and on four unrecoverable errors
  (auth, credits, context overflow compaction could not clear, model unavailable); transient
  errors leave it active. Several turns with no tool use stop the loop with the goal still set.
- **Background work defers the judgement**; idle check-ins come at 30 min, then doubling, at
  most three between your prompts.
- Survives `--resume`/`--continue`; 4,000-character cap; one goal per session; `/goal clear`.
- **There is no pause.** "Stop" in the chat does not stop it: the judge re-prompts after every
  turn (observed: eight re-prompts while the owner was asking questions). To talk to the session,
  `/goal clear` first, then re-paste the goal when done.
- **The state/progress file is the only memory across compaction.** The judge re-renders the
  objective, not the history; anything the next turn needs (round counter, open findings, last
  decision) is written to that file, and the goal names it.
- Headless: `claude -p "/goal …"` runs the loop to completion.

**/goal or /loop?** Official comparison: `/goal` starts the next turn when the previous one
finishes, until a condition holds; `/loop` starts one when a time interval elapses. So: build
work with a verifiable end state → `/goal`. Watching something external on a cadence (a CI run,
another agent's progress, a deploy) → `/loop`. A supervisor that checks a builder every 20
minutes is a loop; the builder is a goal.

## Worked example

`examples/overnight-board-goal.md` — an overnight goal that drives a project board (2,112
characters), reviewed against the official docs on 2026-09-07.

## Goal and review go hand in hand (added 2026-09-13)

The goal outranks the review skill: whatever the skill's stop rule says, a goal whose exit is a
reviewer's approval re-prompts the session until the reviewers approve, and reviewers of a proof
of concept return new, real, shrinking findings every round (observed: 25 rounds, 12 hours, two
reviewer sessions plus a full benchmark run per round, stopped by the owner, not by the goal).
A cap alone is not the fix; the exit condition is. Write the review loop like this:

- exit: "the adversarial-review stop message reads LANDING DECISION land-clean or
  land-with-exceptions" (the driver computes it from the gate: oracle at its bar, red CI, upheld
  BLOCKER/MAJOR, contract items), never "until both reviewers approve";
- the oracle and its pre-registered bar named in the goal text;
- "at most 3 review rounds; round N>1 reviews the delta only; after 3, or on any escalation the
  skill names, record the open findings, produce the stop message, and stop";
- the round counter in the progress file.

Judge rule for Claude's `/goal`: the judge reads the transcript, so the LANDING DECISION line
must appear verbatim in the session's output for the condition to be met.
