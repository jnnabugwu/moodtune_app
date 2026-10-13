#!/usr/bin/env bash
# Mirrors .github/workflows/main.yaml (Very Good Workflows) so failures show up
# before pushing. Usage:
#   tool/ci_check.sh                 # all checks
#   tool/ci_check.sh format analyze  # only the named steps
#   MIN_COVERAGE=90 tool/ci_check.sh test
#
# Steps: deps format analyze test spell title

set -uo pipefail

cd "$(dirname "$0")/.."

MIN_COVERAGE="${MIN_COVERAGE:-80}"
STEPS=("$@")
[[ ${#STEPS[@]} -eq 0 ]] && STEPS=(deps format analyze test spell title)

RED=$'\e[31m'; GREEN=$'\e[32m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
FAILED=()

run() {
  local name="$1"; shift
  printf '\n%s▶ %s%s\n' "$BOLD" "$name" "$RESET"
  if "$@"; then
    printf '%s✓ %s%s\n' "$GREEN" "$name" "$RESET"
  else
    printf '%s✗ %s%s\n' "$RED" "$name" "$RESET"
    FAILED+=("$name")
  fi
}

very_good_cmd() {
  if command -v very_good >/dev/null 2>&1; then
    very_good "$@"
  else
    dart pub global run very_good_cli:very_good "$@"
  fi
}

ensure_very_good() {
  command -v very_good >/dev/null 2>&1 && return 0
  dart pub global list | grep -q '^very_good_cli ' ||
    dart pub global activate very_good_cli >/dev/null
}

cspell_cmd() {
  npx --yes cspell@8 "$@"
}

pr_title() {
  gh pr view --json title -q .title 2>/dev/null || git log -1 --format=%s
}

for step in "${STEPS[@]}"; do
  case "$step" in
    deps)
      run "flutter pub get" flutter pub get
      ;;
    format)
      run "dart format" dart format --set-exit-if-changed lib test
      ;;
    analyze)
      run "flutter analyze" flutter analyze lib test
      ;;
    test)
      ensure_very_good
      run "very_good test (min coverage ${MIN_COVERAGE}%)" very_good_cmd test \
        -j 4 --optimization --coverage --min-coverage "$MIN_COVERAGE" \
        --report-on lib --show-uncovered --test-randomize-ordering-seed random
      ;;
    spell)
      run "cspell (**/*.md)" cspell_cmd --config .github/cspell.json \
        --no-progress --gitignore "**/*.md"
      ;;
    title)
      title="$(pr_title)"
      run "cspell (PR title: \"$title\")" bash -c \
        'printf "%s\n" "$1" | npx --yes cspell@8 --config .github/cspell.json --no-progress stdin' _ "$title"
      ;;
    *)
      echo "Unknown step: $step (expected: deps format analyze test spell title)" >&2
      exit 2
      ;;
  esac
done

echo
if [[ ${#FAILED[@]} -eq 0 ]]; then
  printf '%s%sAll checks passed.%s\n' "$BOLD" "$GREEN" "$RESET"
else
  printf '%s%sFailed: %s%s\n' "$BOLD" "$RED" "${FAILED[*]}" "$RESET"
  exit 1
fi
