---
name: job-done-report
description: How to tell the owner a job is finished. Use at the end of every job, run, review or merge, and whenever he asks "where do we stand". Simple words, zero assumed context, nothing he could misread, as few tokens as possible. Asked for 2026-09-14; rules rebuilt on published evidence 2026-09-15.
---

# Job-done report

Same word rules as `explain-plainly`; this skill fixes the shape for a finished job. A fixed shape
is the one writing change with hard numbers behind it: a fixed handoff format in nine hospitals cut
errors by 23%. Evidence: /mnt/ssd/eval-private/quality/readability-research-2026-09-15.md.

He reads one message, cold, on a phone, with no memory of the names we used. If he misreads it, we
both die: every sentence must be one he cannot read two ways.

## Shape, in this order, nothing else

1. **Result.** One line: done / not done / done except X. First, before any reason.
2. **Needs you.** A decision or an act only he can do, with the owner named, or the word
   "nothing". Second, so a reader who stops after two lines knows the state and his ask.
3. **What it means for you.** What is different on his machine or in his product, in plain words:
   "Before, X. Now, Y." One to three sentences.
4. **Verified how.** Who checked and whether they ran or only read: "the finish line passed on a
   fresh clone", "the reviewer ran the failing case", "I read the code only". Add a link or a path
   only when a relevant one already exists (the run's page, the commit, the findings file, the
   report); never make one up and never omit the sentence because there is no link.
5. **What went wrong.** Only things that cost time, money or trust, each one sentence with the
   cause and the word "fixed" or "not fixed". My own mistakes in the same voice as the workers'.
   Dropped when nothing did.
6. **Not done.** What was left out or is still open, and the risk it leaves. Dropped when empty.
7. **Next.** One line: what I do next unless he says otherwise, and when he hears from me again.

A number only when it changes what he does (money, time, a score), as digits, in a short table when
there are several. Model names only when the roster was his question. Evidence for the shape:
agent reports claim unimplemented work often enough (45% of inconsistent agent pull requests, 23%
of real-session failures) that "verified how" is the one slot the reader cannot do without.

## Words

- Sentences under 25 words, average 15. One idea per sentence.
- Say what is true, never what is not: "the check passed", not "the check did not fail".
- One name per thing, used every time. "The worker" not "the attempt"; "the check that must pass"
  not "the proof"; "the list of models" not "the lineup". Never a synonym for a thing already named.
- No pronoun without its noun in the same sentence.
- No file name, commit id, session id, node number, store path, flag or command in the prose. A link
  or path only when he must click it.
- Dates, not "yesterday" or "now". Digits for numbers.
- Name the actor: "the reviewer rejected it", "I broke the test script".
- Hedge only where truly unsure, in the first person. Never confident wording about an unverified
  claim.
- No narration of my process, no "I then ran", no pleasantries, no recap, no closing offer.

## Budget

Under 120 words for one job, under 200 for a day of several jobs. Result and Needs-you are one line
each. Cut by leaving out, never by packing sentences, never by dropping a "what went wrong" item.

## Example (the owner-verbs job, 2026-09-14)

**Done.** You can now stop, resume, add a rule to, or force the state of a running job from the
command line, and the running engine obeys within a few seconds.

**Needs you:** nothing.

**What went wrong.** My own test script was wrong: it assumed starting a job does not also run the
work, so the test kept finishing a fake job with real, paid model calls. Fixed. While repairing it I
found a real bug: an order to start a worker that was queued before a job finished still fires after
it finishes. Not fixed.

**Verified how.** The finish line passed twice on a fresh clone, and the reviewer ran each rejected
case before accepting the fix; run page http://localhost:8777/?run=rt-j26.

**Next:** fix that bug as the next job; you hear from me when it lands.

## Before sending

Read it once as someone who has never seen this project. A defect is: a word you would have to look
up; an "it" or "this" whose noun is not in the same sentence; a sentence readable two ways; a
sentence over 25 words; a negative that could be a positive; a slot out of order; a "done" with no "verified how".
