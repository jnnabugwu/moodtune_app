---
name: Agent-ready task
about: A feature or bug written so an agent can build it without asking. Model it on #35.
title: "fix(scope): "
labels: []
---

<!--
  Write for an agent that knows only CLAUDE.md and this issue.
  Every claim about the code should cite a path:line on main.
  The title is the PR title, so use a Conventional Commit.
-->

## Summary

<!-- One or two sentences: what changes for the user. -->

## Current state (verified against `main` @ <short SHA>)

<!--
  For a bug: steps to reproduce, the actual and the expected behavior, and the
  line that causes it. For a feature: the files and widgets it builds on.
-->

| Where | What it does now |
| --- | --- |
| `lib/...:NN` | |

## Requirements

<!-- Numbered, so PRs and tests can cite them. Leave out what's in Non-goals. -->

- **R1.**

## Non-goals

-

## Acceptance criteria

<!-- Each one must be checkable by a test or by a named manual step. -->

- [ ] **AC1.**

## Tests

<!--
  The tests to add or change, by file. Name any existing test that asserts the
  current (buggy) behavior: fixing the bug means changing it.
-->

-

## Definition of done

- [ ] All ACs pass. Manual ACs have screenshots or a recording in the PR.
- [ ] `tool/ci_check.sh` passes locally (format, analyze, tests at 80% coverage, cspell, PR title).
- [ ] No drop in coverage on the files you touched.
- [ ] Branched from `main`; the PR references this issue and the R/AC IDs it covers.

## Decisions required

<!--
  Anything the agent must not decide alone, each with a recommended default.
  Delete this section if there are none. Don't start work while one is open.
-->

## Notes for the implementing agent

<!-- Traps, files not to touch, patterns to copy. -->

-
