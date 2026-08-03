# skills

Reusable [Claude Code](https://claude.com/claude-code) skills.

A skill is a folder with a `SKILL.md` — instructions Claude loads on demand when the task
matches, or when you type `/<name>`.

## Install

Clone anywhere, then symlink the skills you want into your Claude skills directory:

```bash
git clone git@github.com:YotamPeled/skills.git ~/src/skills
ln -s ~/src/skills/adversarial-review ~/.claude/skills/adversarial-review
```

`~/.claude/skills/` = available in every project. `<project>/.claude/skills/` = that project only.

## Skills

### `adversarial-review`

Launches **two independent Opus reviewer agents in parallel** over a plan doc, a branch diff,
or any artifact — then merges their findings.

The pair differs in *method*, not topic, which is what makes it worth twice the tokens:

- **A — the auditor** verifies by READING: does the artifact's story match the code? Callers
  that supposedly don't exist, contracts that move, migrations that break a live path, drift
  from the spec.
- **B — the breaker** verifies by DOING: boots the thing in scratch containers, runs the test
  suite, crafts hostile input, races concurrent calls, kills a dependency mid-operation. Every
  finding must ship with a reproducible sequence and real observed output — no "this looks
  fragile".

Findings come back severity-ranked (BLOCKER/MAJOR/MINOR/NIT) with a verdict. Anything both
reviewers surface independently is near-certain; verify the serious ones yourself before
acting, then fold the accepted fixes back into the spec so it stays the source of truth.

Each reviewer also reports what it checked and *cleared* — that list is half the value, since
it separates "verified safe" from "never looked at".

**Track record** (one microservice, three rounds): the auditor caught a plan built on a false
premise and a migration that would have broken a live admin path; the breaker caught an
endpoint that 500'd under ordinary concurrency, non-atomic account deletion that orphaned
data and resurrected deleted accounts, a rate limit that throttled the whole site as one
bucket, and a config that would have crashlooped in production.

Cost: two long-running Opus agents per invocation. Worth it before a merge, overkill for a
one-line change.
