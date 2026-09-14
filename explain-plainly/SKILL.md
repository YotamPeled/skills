---
name: explain-plainly
description: Explain a concept, decision or trade-off to the owner in plain English as if this were the one message he gets and he knows nothing. Use for every explanation of a design, a method, a mechanism or a recommendation; the owner asked for this style permanently on 2026-09-10 ("keep using it forever"), on 2026-09-14 added "if he misreads it we both die, and as few tokens as possible", and on 2026-09-15 had the rules rebuilt on published evidence. Finished jobs use job-done-report instead.
---

# Explain plainly

The owner reads one message, cold, on a phone, with no shared vocabulary. If he misreads it, we both
die: every sentence must be one he cannot read two ways. Short is how you get there, not a reason
to leave a part out. Evidence for every rule below: /mnt/ssd/eval-private/quality/readability-research-2026-09-15.md.

## Answer first, then shape to the question

The first sentence answers the question. Eye-tracking: 81% of readers see paragraph one, 32% see
paragraph four. Then:

- A yes/no or "which" question: the answer, one reason, stop.
- A "how does X work" question: what happens, in the order it happens, naming each participant by
  what it does the first time ("a manager agent, which we call a supervisor").
- A design or a decision: **Today** (how it works now, as a story) → **What goes wrong** (where
  reality departs, who notices, what is lost) → **The idea** (defined by contrast with today; what he
  would see differently) → **The danger** (two or three failure modes, one sentence each with its
  cause) → **I recommend** (one decision, one sentence per danger; who agreed or disagreed). A part
  with nothing to say is dropped, not padded.

Bold the label of each part. No headers. Bullets only for three or more truly separate items, never
more than four items, the load-bearing word first.

## Words (each rule has a study or a standard behind it)

- **Sentences under 25 words, average 15.** Subject and verb next to each other. One idea per
  sentence: a fact or a consequence, never both.
- **Say what is true, never what is not.** Negatives are read slower and misread three times as
  often. "The check passed" not "the check did not fail".
- **One name per thing, used every time.** Pick the plainest word once ("the engine") and never
  swap in a synonym ("the system", "the runtime"); a new word reads as a new thing.
- **No pronoun without its noun in sight.** Repeat the noun instead of "it", "this", "that one".
- **Zero jargon.** Every term of ours (front, node, proof, cut, fold, sha, rebase, pool) is replaced
  by its plain meaning or defined in the same sentence the first time. Test: would a smart person
  outside software know this word?
- **No code name, file name, id, flag or command in the prose.** Say what the thing does. A path or
  link only when he must click it.
- **Dates, not relative time.** "on 14 September", never "yesterday", "now", "currently".
- **Numbers as digits**, one per sentence at most, only when the number changes what he does.
- **Name the actor** when who did it matters: "the reviewer rejected it", not "it was rejected".
- **Concrete over abstract.** One real example from our work beats a general statement.
- **Hedge only where truly unsure, and in the first person:** "I am not sure, but". Never "it is
  unclear". Never a confident sentence about something unverified.
- **No narration of my process, no pleasantries, no recap, no closing offer.** Stop when the
  content stops.

## Budget

A concept: under 100 words. A design with a recommendation: under 150. Half of any message longer
than about 110 words goes unread. Hard content gets the words it needs: cut by leaving out a second
example, a history, a caveat that changes nothing he does, never by packing sentences and never by
dropping a step he must act on.

## Before sending

Read it once as someone who has never seen this project. A defect is: a word you would have to look
up; an "it" or "this" whose noun is not in the same sentence; a sentence readable two ways; a
sentence he does not need in order to act; a sentence over 25 words; a negative that could be
stated as a positive.
