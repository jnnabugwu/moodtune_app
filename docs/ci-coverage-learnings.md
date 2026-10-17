# MoodTune: CI coverage & review session — learnings

_As of 2026-10-13_

## Summary

Line coverage went from 14.8% to 86.3%, CI now gates at 80%, and both open PRs ended green. The PRs were #17 (Jamendo fix) and #16 (on-device narration).

- **Started from:** a failing CI run on #17. Spell-check failed on the word "Jamendo" in the PR title. The build failed because the Very Good workflow defaults to 100% coverage and the app had 14.8%.
- **Built:** `tool/ci_check.sh`, which runs the CI steps locally, and a shared test harness. Six parallel agents then wrote 70 test files, 637 tests in all.
- **Then:** #16 broke after `main` merged in, because `ResultsPage` needed a GetIt registration the new tests didn't make. Next came 11 cubic review comments on the narration code, all fixed.
- **Ended at:** 666 tests passing under CI's settings, CI green on #16, and 17 real bugs found by the new tests. 15 of those are still open.

## Timeline

Each problem surfaced only after the previous one was fixed; in order:

| # | Problem | Root cause | Resolution |
| --- | --- | --- | --- |
| 1 | #17 spell-check failed | The spell-check job also checks the PR title; "Jamendo" wasn't in the dictionary | Added it to `.github/cspell.json` |
| 2 | #17 build failed at 14.8% coverage | `flutter_package.yml` defaults `min_coverage` to 100 | Set `min_coverage: 80` |
| 3 | No way to see this before pushing | CI steps only ran on GitHub | `tool/ci_check.sh` runs format, analyze, tests with the gate, and cspell on the docs and the PR title |
| 4 | Coverage far below 80% | Only Spotify had tests | Shared harness, then 6 agents in parallel on separate files; 86.3% |
| 5 | 2 tests passed alone but failed in the full suite | CI runs every test file in one isolate; an earlier widget test left a stub `HttpClient` that answers 400 | Tests save and restore `HttpOverrides`, Supabase and talker state |
| 6 | Merging #18 blocked | The permission classifier refused a merge with no review or CI | You merged #18 and #17 by hand |
| 7 | #16 failed 12 `ResultsPage` tests | CI tests the PR merged with `main`; the page calls `getIt<MoodNarrator>()` and the tests from `main` never registered one | Registered a narrator with an unavailable engine in those tests |
| 8 | Generation kept running after the 5 s timeout | Dart's timeout only stopped Dart waiting; the Swift `Task` was never cancelled | Dart passes `timeoutMs`; Swift races generation against it and cancels |
| 9 | 10 more cubic comments | Gaps in output validation, caching and layering | All fixed, with a test for each |

## Learnings: CI and the Very Good workflows

Most failures came from workflow defaults and triggers, not from the code under test.

- **Reusable workflows hide defaults.** `flutter_package.yml@v1` ships `min_coverage: 100`. Read the called workflow's inputs, not just your own YAML.
- **The PR title is checked too.** The spell-check job runs cspell on the title, so a new proper noun in a title fails CI even when no file changed.
- **Coverage counts only imported files.** With `collect_coverage_from: imports`, a file no test imports isn't in the total. The baseline was 14.8% that way and 1.4% across all of `lib`. Adding a router test pulled in the untested Spotify pages and lowered the total slightly.
- **CI only runs on PRs into `main`.** The stacked PR #18 targeted the Jamendo branch and got no CI, which is part of why its merge was blocked.
- **A PR's CI tests the merge with its base.** #16 failed although nothing on the branch changed, because `main` had gained tests that met its code for the first time.
- **Mirror CI locally, exactly.** The local script uses the same flags as CI (`--optimization`, random ordering, `--min-coverage`). Running tests one file at a time would have hidden the shared-isolate failures.

## Learnings: Flutter testing

A shared harness built first, plus care with global state, mattered more than any single test.

- **Build the harness before the tests.** `test/helpers/pump_app.dart` mounts a page in the real ShadApp and `CupertinoApp.router` shell with mock BLoCs. Its GoRouter `errorBuilder` renders `navigated:<path>`, so any navigation can be asserted with one finder. Six agents used it and their tests read alike.
- **One isolate means shared globals.** `very_good test --optimization` merges every file. `HttpOverrides`, `Supabase.initialize`, `talker.disable()` and GetIt registrations leak across files unless restored in `tearDown`.
- **Service lookups in widgets are hidden test dependencies.** `getIt<MoodNarrator>()` inside `ResultsPage` broke 12 tests the moment narration met them. Constructor injection, or a provider in the tree, would have made the dependency visible.
- **`pumpAndSettle` never settles with repeating animations.** Waveforms and spinners need `pump()` or `pump(Duration)`; periodic timers need the tree unmounted before the test ends.
- **Fake plugins without importing their platform packages.** Extending `FilePicker` and mocking the url_launcher and just_audio method channels avoided the `depend_on_referenced_packages` lint.
- **Run several random seeds.** Five seeds passed before calling the suite stable. One 5-minute run turned out to be CPU contention from parallel agents, not a hang.
- **Fresh checkouts need generated code.** `lib/l10n/gen` is gitignored; tests won't compile until `flutter gen-l10n` runs.

## Learnings: parallel agents and workflow

Splitting the work six ways took about 45 minutes of wall time with no merge conflicts, but the merged result still needed its own verification.

- **Give each agent its own files.** Each agent owned a set of `lib/` files and one fixtures file, and none of them edited the shared harness. All six results copied in without a single conflict.
- **Check what a worktree is built from.** The worktrees were cut from `main`, not the working branch. One agent then reported the missing Jamendo `await` as a new bug, although this branch already had the fix.
- **Verify the merge, not the parts.** Every agent's tests passed in its own worktree; the combined suite still failed twice (shared-isolate state).
- **Pin behaviour; report bugs separately.** Agents never changed `lib/`. Where code was wrong they either tested the current behaviour and said so, or left that case out, so a later fix breaks few tests.
- **Expect permission gates on outward actions.** A merge with no review or CI was refused, and so was the next step in that sequence. Plan for a person to do merges, or allow them explicitly.
- **Treat review bots as a checklist, not a verdict.** All 11 cubic comments were worth acting on, but one could only be partly fixed: regex validation can't prove a generated sentence is factual.

## Bugs the tests surfaced

Writing tests against real behaviour exposed 17 bugs. Most open ones are in state handling, and the first four share one cause: `copyWith` treats `null` as "keep the old value".

| Bug | Where | Status |
| --- | --- | --- |
| `copyWith` can't clear `user`: the old user survives sign-out | `auth_state.dart:37` | Open |
| `copyWith` can't clear the upload or catalog result: the catalog screen shows the previous upload | `analysis_state.dart:85`, `:92`; `results_page.dart:110` | Open |
| `passwordResetSent` never resets: "Link sent" sticks on later visits | `auth_state.dart:42`, `forgot_password_page.dart:79` | Open |
| Every `copyWith` clears all four error fields unless re-passed | `analysis_state.dart:84` | Open |
| `_initials` throws `RangeError` for emails like `john_@x.com` | `home_auth_page.dart:206` | Open |
| Any error containing "rate" ("generate") shows the rate-limit screen | `analysis_loading_page.dart:170` | Open |
| "Try again" on the loading error screen doesn't resend the request | `analysis_loading_page.dart:158` | Open |
| Signing in on the legacy auth page lands on the guest screen | `auth_page.dart:61` | Open |
| History rows do nothing when tapped | `home_auth_page.dart:154`, `history_page.dart:217` | Open |
| The "Saved" notice is an empty stub | `results_page.dart:312` | Open |
| Repositories catch only `Exception`; a malformed payload's `TypeError` escapes | `analysis_repository_impl.dart:34` | Open |
| `sendTimeout` maps to a server error, not a network error | `analysis_repository_impl.dart:96` | Open |
| `getHistory` ignores playlist history and doesn't sort | `analysis_repository_impl.dart:40` | Open |
| 401 retry uses a bare `Dio`: no logging or Sentry, multipart can't be re-sent | `auth_interceptor.dart:27` | Open |
| Leftover debug code writes `debug_connect.log` | `connect_spotify_page.dart:26` | Open |
| Mood-only Jamendo search skipped error mapping (missing `await`) | `jamendo_remote_datasource.dart:59`, #17 | Fixed |
| Narration kept generating after the 5 s timeout | `AppDelegate.swift`, #16 | Fixed |

## Follow-ups and recommendations

- [ ] Fix the `copyWith` family in one PR: a `_keep` sentinel for nullable fields (already used for `historyMoodFilter`), plus resetting `passwordResetSent`.
- [x] Run CI on every pull request, not only those into `main`, so stacked PRs get checked. Done in #34.
- [ ] Replace `getIt` lookups inside widgets with constructor injection or a provider, starting with `ResultsPage`.
- [ ] Run `tool/ci_check.sh` from a pre-push hook.
- [ ] Test the narration deadline on a device with Apple Intelligence.
- [ ] Add Spotify tests, or decide to leave Spotify out of the coverage total. It is the main reason coverage isn't higher.
- [ ] Work through the open rows in the bugs table above. Filed as #38–#48 on 2026-10-17; see `software-factory-learnings.md`.
