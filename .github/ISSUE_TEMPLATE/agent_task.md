---
name: Agent-ready task
about: A feature or bug written so an agent can build it without asking. Model it on #35.
title: ""
labels: []
---

<!--
  Write for an agent that knows only CLAUDE.md and this issue.
  Every claim about the code should cite a path:line on main.
  Title the issue with the full Conventional Commit the PR should use, e.g.
  `feat(sharing): share mood results to Instagram Stories and X`.
  GitHub doesn't copy it to the PR: the agent sets the PR title to it, and
  CI's semantic-pull-request check validates the PR title, not this one.
-->

## Summary

<!-- One or two sentences: what changes for the user. -->

## Current state (verified against `main` @ <short SHA>)

<!--
  For a bug: steps to reproduce, the actual and the expected behavior, and the
  line that causes it. For a feature: the files and widgets it builds on.
  If an AC is a command (a grep, a test run), run it on main now and list
  every hit here, not only the file you found first.
-->

| Where | What it does now |
| --- | --- |
| `lib/...:NN` | |

## Requirements

<!--
  Numbered, so PRs and tests can cite them. Leave out what's in Non-goals.
  Offer an "or" fallback only after checking it can be built.
-->

- **R1.**

## Non-goals

<!--
  Include code paths with the same bug that this issue leaves alone, so the
  agent knows they were skipped on purpose (or move them into Requirements).
-->

-

## Acceptance criteria

<!-- Each one must be checkable by a test or by a named manual step. -->

- [ ] **AC1.**

## Tests

<!--
  The tests to add or change, by file. Name any existing test that asserts the
  current (buggy) behavior: fixing the bug means changing it.
  Cite test files by path. If the code has no tests, say so; never write
  "existing tests pass" without checking that they exist.
-->

-

## Definition of done

- [ ] All ACs pass. Manual ACs have screenshots or a recording in the PR.
- [ ] `tool/ci_check.sh` passes locally (format, analyze, tests at 80% coverage, cspell on the docs and the PR title).
- [ ] The PR lists the coverage of the `lib/` files you touched (`tool/ci_check.sh test coverage`) and explains any below 80%.
- [ ] Branched from `main`; the PR references this issue and the R/AC IDs it covers.
- [ ] The PR title is this issue's title: a complete Conventional Commit (`type(scope): subject`). `tool/ci_check.sh` only spell-checks it; the semantic-pull-request check in CI enforces the format.

## Decisions required

<!--
  Anything the agent must not decide alone, each with a recommended default.
  Delete this section if there are none. Don't start work while one is open.
-->

## Notes for the implementing agent

<!-- Traps, files not to touch, patterns to copy. -->

-
