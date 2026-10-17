# MoodTune: software factory setup — learnings

_As of 2026-10-17_

## Summary

"Operational" here means an agent can take a GitHub issue, build it in its own worktree and open a PR. CI then decides whether that PR is allowed to merge, and Jordan reviews and merges it. On 2026-10-17 MoodTune got there, and the first issue run through it came back green.

- **Started from:** app CI that ran only on PRs into `main`, no backend CI, a CLAUDE.md that described an older app, one issue (#35) in the tracker, and nothing that made a red check block a merge.
- **Built:** CI on every PR in both repos, tests that never reach a real Supabase project, an issue template written for agents, 15 known bugs filed as 11 issues (#38–#48), and required checks on `main` with no bypass.
- **First run:** an agent given only "implement #48" opened #51 about 8.5 minutes later. All three required checks passed on the first push, and the diff needed no changes in review.
- **Also learned:** the agent's friction log was the most useful output of the run. About half of what it reported was real, and the other half traced back to a stale copy of CLAUDE.md in its context.

## What was built

| Piece | Where | What it does |
| --- | --- | --- |
| CI on every PR, iOS simulator check, CLAUDE.md rewrite, docs moved in | app #34 | Stacked PRs get CI. Native decoder → YAMNet runs on a simulator. Agents read current instructions. |
| Backend CI | backend #11 | `pytest` on Python 3.13 for every PR and push to `main`, no secrets, about 40 s |
| Hermetic backend tests | backend #11, `tests/conftest.py` | Supabase, Spotify and Sentry settings point at dead addresses before `app` is imported |
| Agent-ready issue template | app #37, `.github/ISSUE_TEMPLATE/agent_task.md` | Current state with `path:line` and a SHA, numbered R and AC, tests to change, a decisions gate |
| Bug backlog | app #38–#48 | The 15 open bugs from `ci-coverage-learnings.md`, grouped by the code they touch, re-verified on `main` |
| Required checks | ruleset "required checks", both repos | App: `build / build`, `semantic-pull-request / build`, `spell-check / build`. Backend: `pytest`. Strict (branch must be up to date), no bypass actors. |
| First agent-built PR | app #51 (closes #48) | Avatar initials no longer crash on emails with empty segments |

`integration-test` (the iOS simulator check) is deliberately not required yet. Make it required once it has run reliably for a while.

## Timeline

Each problem surfaced only after the previous one was fixed; in order:

| # | Problem | Root cause | Resolution |
| --- | --- | --- | --- |
| 1 | Backend tests crashed on collection with no env file (`supabase_url is required`) | Five `app/crud/` and `app/services/` modules build a Supabase client at import time | `tests/conftest.py` sets test values in the process environment before `app` is imported |
| 2 | On a laptop the same tests passed, using the real dev project | `dev.env` supplied the real URL and service key; any unmocked call would have reached it | Same fix. Process env vars outrank the env file in pydantic-settings, so the test values win even when `dev.env` is present. |
| 3 | Fake keys rejected (`Invalid API key`) | supabase-py checks that keys are JWT-shaped | Keys like `test-anon.not-a.real-jwt` |
| 4 | First backend CI run red: `No module named 'app'` | CI ran bare `pytest`; the local check ran `python -m pytest`, which adds the working directory to `sys.path` | `pytest.ini` with `pythonpath = .`. cubic flagged the same thing on the PR. |
| 5 | The local venv was Python 3.12; Railway deploys 3.13 | The old venv predates `runtime.txt` | Reproduced CI in a fresh 3.13 venv in a clean worktree with no env files |
| 6 | CLAUDE.md said "`main` only accepts changes that pass them" while nothing was enforced | #34 documented the intended state before it existed | Created the rulesets, so the sentence became true |
| 7 | Decisions were posted against the wrong issue numbers | Numbers were inferred from the order the issues were filed in, not read from what `gh` returned | Caught when an edit found no "Decisions required" section. Re-mapped by title and fixed. |
| 8 | Issues cite `docs/ci-coverage-learnings.md`, which wasn't on `main` | The doc was never committed | Committed alongside this one |
| 9 | The first agent reported CLAUDE.md gaps that `main` had already fixed | A subagent inherits the CLAUDE.md loaded when the parent session started, which was before #34 merged | Tell spawned agents to re-read CLAUDE.md from their own worktree |

## Learnings: CI

- **Make tests hermetic before adding CI.** CI with no env file is the first place a hidden dependency on real credentials shows up. The silent case is worse than the crash: on a laptop, tests looked fine while holding the dev project's service key.
- **Mirror CI's exact command.** `python -m pytest` and `pytest` differ in what they put on `sys.path`. `ci-coverage-learnings.md` reached the same conclusion for Flutter flags. Reproduce CI in a clean checkout, on the deployed runtime version, with no env files.
- **A CI signal isn't a gate.** Until the rulesets existed, a red PR could still be merged. With agents opening PRs, required checks are what stand between an agent's mistake and `main`.
- **No bypass, because agents push as you.** Agents use Jordan's GitHub credentials, so any bypass for Jordan is a bypass for every agent. The cost: version bumps (like `f7115cc`) can't be pushed straight to `main` anymore and need a PR.
- **Strict mode re-checks stale branches.** A PR that went green against an older `main` has to be updated and re-run before it merges. That's the failure that hit #16 in the coverage session. The cost is an "Update branch" click when several agent PRs land close together.
- **Pin checks to GitHub Actions.** Each required check is tied to the Actions app (integration ID 15368), so another app can't post a passing status under the same name.

## Learnings: tickets agents can build from

- **Verify on `main` before filing.** All 15 "open" bugs from 10-13 were checked against current `main` first. All were still open, but the line numbers had moved. Quote the line, not only the number.
- **Pin a SHA, and expect it to go stale.** #48 said `a4ed99d`; three merges later `main` was `ced0b84`. Because the issue quoted the code, the agent could still find it. Refresh the SHA when you touch an issue.
- **Write requirements as invariants, not only examples.** #48's ACs listed `john_@x.com` and `_@x.com`. The agent found a third crash path (`@x.com`, through `substring` on an empty string) because R2 said "any email … never throws". Without that line, the examples alone would have let the bug through.
- **Name the tests that lock in the bug.** Several existing tests assert the current buggy behavior ("Documents current behaviour"). Listing them in the issue tells the agent that changing them is expected, not a regression.
- **Gate on decisions explicitly.** Three issues needed a product call: #42 (redirect vs. delete), #43 (what a tap opens) and #45 (playlists in history). Each says "don't start until answered". Answers go in a comment *and* replace the Decisions section, so an agent reading only the body sees them.
- **Group by code, not by bug.** 15 bugs became 11 issues: bugs that share a root cause or a file went together (the `copyWith` family, the error-typing gaps), so each issue is one PR.
- **Use the URLs `gh` returns.** Issue numbers are assigned when each issue is created. Don't infer them from the order you filed them in.

## Learnings: running an agent

- **Give it the issue and nothing else.** The #48 prompt was the issue number, the repo, a worktree command and the rules (open a PR, don't merge, wait for required checks). Whatever the agent had to guess shows where the ticket or the docs fall short.
- **Ask for a friction log.** The most useful output wasn't the PR but the list of everything that was wrong, missing or surprising. Real gaps it found:
  - "No drop in coverage on the files you touched" has no tooling. `very_good test` prints no per-file percentage, so the agent worked it out from `coverage/lcov.info` by hand.
  - There are two cspell configs (`cspell.json` at the root and `.github/cspell.json`). CI uses the second, and nothing says what the first is for.
  - `tool/ci_check.sh`'s title step falls back to the last commit subject when there's no PR yet, so it only means something after you commit.
  - Test output is buried in Talker `[warning]` lines and the uncovered-lines list. The agent had to grep for the result.
- **Check the log against `main` before acting on it.** About half the CLAUDE.md complaints described the old file: no `ci_check.sh`, the old test command, three features instead of seven. The current file covers all of those. The agent was reading the copy loaded when the parent session started.
- **Review is still yours.** The diff was small and correct. It removed an early return that the new empty-parts branch already covered, and the 7 new cases failed before the fix and passed after. Green checks plus a person reading the diff is the bar. Checks alone aren't.

## Batch 2

Five issues ran in parallel on 2026-10-17 (PRs opened 21:54–21:58, all merged by 22:09). They ran from the laptop, not the cloud: every commit carries the local VS Code co-author line and none links a cloud session. There was no friction log this time, so everything below comes from the PRs, their CI runs and `main`.

| PR | Closes | First push green | Review rounds | Merged |
| --- | --- | --- | --- | --- |
| #55 | #42 auth redirect | yes | 0 | 22:00 |
| #56 | #47 Spotify debug logging | yes | 0 | 22:03 |
| #58 | #38 `AnalysisState.copyWith` | yes | 0 | 22:05 |
| #60 | #46 401 retry | yes | 0 | 22:07 |
| #57 | #39 sign-out, "Link sent" | yes | 1 (cubic) | 22:09 |

**What held up.** All five passed the required checks on the first push. Nobody complained about CLAUDE.md, so the stale-copy problem from #51 didn't come back. #57, #58 and #60 each say they reverted the fix and watched the new tests fail.

**What went wrong**, each checked against `main` @ `9392072`:

1. **#47 under-described the bug.** Its AC1 grep also matches a `#region agent log` block in `spotify_bloc.dart`, which was already there at the SHA the issue cites (`a4ed99d`), but "Current state" listed only the page. AC2 relied on "existing page tests" for `ConnectSpotifyPage`, and there are none. The agent handled both, but the issue was written from one file and its own check command was never run. *Fixed in the template:* run any command AC on `main` and list every hit; cite test files by path or say there are none.
2. **#46 offered a fallback that can't be built.** R3 said "retry with a fresh `FormData`, or fail with a clear `Failure`". Dio raises the single-use-file `StateError` asynchronously, outside the future the interceptor sees, so the second half isn't possible. *Fixed in the template:* offer an "or" only after checking it.
3. **#39 left a sibling path alone.** The issue named email sign-in and sign-up, so the agent left `_onSocialSignInRequested` as it was. On `main` its failure branch still emits `copyWith` without `user: null`, so a failed social sign-in keeps the previous user. It's low impact, but the agent couldn't tell whether the omission was deliberate. *Fixed in the template:* Non-goals now asks for paths with the same bug that the issue skips.
4. **Only the AI reviewer caught the real defect.** In #57, cubic found that overlapping reset requests could let an older success set "Link sent" after a newer failure. The local checks and the agent both missed it. It was the batch's only fix round.
5. **Strict mode serialized the merges.** By 22:00 four PRs were green, but each merge made the rest stale: 4 of 5 had to merge `main` and re-run `build / build` (about 1.5–2 minutes each). Landing five green PRs took 9 minutes. A merge queue would take this over; not set up yet.
6. **A Still-open item from #51 cost time again.** #57, #58 and #60 all worked out per-file coverage by hand from `lcov.info`. *Fixed:* `tool/ci_check.sh test coverage` prints it, and the template's "no drop in coverage" (which nothing could check) became "list it and explain anything under 80%".
7. **An agent found a security bug outside its scope.** #56 noticed `lib/bootstrap.dart:55` logs the full Supabase access token with `talker.info`. Filed as #59; still on `main`.

### Cloud vs laptop

Batch 2 gives no comparison, because it didn't run in the cloud. Checking it from a cloud session (claude.ai/code) did show what a cloud batch will hit:

- **Works out of the box.** Flutter 3.47.5 is preinstalled. `tool/ci_check.sh deps format analyze` passes with no env files; `flutter analyze` alone took 53 s. `deps test` took 100 s, against 35 s for every step on the laptop, so expect the local check to take about 3 times as long.
- **The repo has to be attached with push access.** An anonymous clone reads code, but the GitHub API returns 403 and nothing can be pushed.
- **GitHub GraphQL is blocked.** `gh pr view`, `gh pr list` and `gh pr create` fail. `ci_check.sh`'s title step used `gh pr view`, so in the cloud it silently spell-checked the last commit subject instead of the PR title. *Fixed:* it now uses the REST API, and CLAUDE.md gives the REST command for opening a PR.
- **No iOS simulator**, so the `integration_test/` check and anything under `ios/` can't be verified in a session.

These are in CLAUDE.md under "Cloud sessions", so the next agent starts with them.

## Numbers

| Measure | Value |
| --- | --- |
| Backend suite | 80 tests, about 1 s locally; about 40 s per CI run including installs |
| App local check (`tool/ci_check.sh`, all steps) | 35 s |
| App CI, `build / build` | 1 min 42 s (batch 2: 1 min 16 s to 1 min 54 s) |
| `tool/ci_check.sh deps test` in a cloud session | 100 s |
| Batch 2, five PRs from open to all merged | 15 minutes (21:54 to 22:09), 9 of them waiting on strict-mode re-runs |
| #48, issue to all checks green | about 8.5 minutes, no fix rounds |
| Backend routers with tests | 3 of 11 (mood observations, history, Spotify) |

## Still open

- [x] Review and merge #51.
- [ ] Work through #40, #41, #43, #44 and #45 (#38, #39, #42, #46 and #47 merged in batch 2). #43 and #45 have their decisions recorded and are ready.
- [ ] Fix #59: the Supabase access token is logged at startup.
- [ ] Failed social sign-in keeps the previous user (`_onSocialSignInRequested`); file it, or fold it into another auth issue.
- [ ] Turn on a merge queue so parallel agent PRs don't each need a manual "Update branch".
- [ ] Run a batch from the cloud to get a real cloud-vs-laptop comparison.
- [ ] When spawning an agent from a long session, tell it to re-read CLAUDE.md in its worktree before starting.
- [x] Add a per-file coverage summary to `tool/ci_check.sh` (the `coverage` step).
- [ ] Decide what the root `cspell.json` is for, or remove it.
- [ ] Quiet Talker in tests, or print a one-line pass/fail summary at the end of `ci_check.sh`.
- [ ] Backend tests for analysis, audio upload, song analysis and catalog, the routers an agent is most likely to change.
- [ ] Make `integration-test` a required check once it has proven stable.
- [ ] Send version bumps through a PR now that `main` rejects direct pushes.
