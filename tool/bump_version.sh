#!/usr/bin/env bash
# Bumps the app version in pubspec.yaml (`version: X.Y.Z+N`). Every bump also
# increments the build number N, since stores reject a reused one.
#
# Usage:
#   tool/bump_version.sh                  # build:  1.0.0+7 -> 1.0.0+8
#   tool/bump_version.sh patch            # patch:  1.0.0+7 -> 1.0.1+8
#   tool/bump_version.sh minor            # minor:  1.0.0+7 -> 1.1.0+8
#   tool/bump_version.sh major            # major:  1.0.0+7 -> 2.0.0+8
#   tool/bump_version.sh 1.2.0            # set:    1.0.0+7 -> 1.2.0+8
#
# Options:
#   --commit    commit pubspec.yaml alone as "chore(release): vX.Y.Z+N"
#   --tag       also create an annotated tag vX.Y.Z+N (requires --commit)
#   --dry-run   print the new version without changing anything
#
# Note: Codemagic's iOS workflow takes only X.Y.Z from pubspec.yaml and sets
# the build number to the latest TestFlight build + 1. Android uses both.

set -euo pipefail

cd "$(dirname "$0")/.."

PUBSPEC="${PUBSPEC:-pubspec.yaml}"
BUMP="build"
COMMIT=false
TAG=false
DRY_RUN=false

usage() {
  # Print the header comment, stopping at the first line that isn't one.
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
  exit "${1:-0}"
}

for arg in "$@"; do
  case "$arg" in
    build | patch | minor | major) BUMP="$arg" ;;
    [0-9]*.[0-9]*.[0-9]*) BUMP="$arg" ;;
    --commit) COMMIT=true ;;
    --tag) TAG=true ;;
    --dry-run) DRY_RUN=true ;;
    -h | --help) usage 0 ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage 2
      ;;
  esac
done

if $TAG && ! $COMMIT; then
  echo "--tag needs --commit, so the tag points at the bump." >&2
  exit 2
fi

current="$(grep -m1 '^version:' "$PUBSPEC" | awk '{print $2}')"
if [[ ! "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]]; then
  echo "Can't parse version '$current' in $PUBSPEC (expected X.Y.Z+N)." >&2
  exit 1
fi
major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
build="${BASH_REMATCH[4]}"

case "$BUMP" in
  build) ;;
  patch) patch=$((patch + 1)) ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  major) major=$((major + 1)); minor=0; patch=0 ;;
  *)
    if [[ ! "$BUMP" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
      echo "Version must look like X.Y.Z, got '$BUMP'." >&2
      exit 2
    fi
    new_name="$BUMP"
    old_name="$major.$minor.$patch"
    # sort -V puts the larger version last; refuse to go backwards.
    if [[ "$new_name" != "$old_name" &&
      "$(printf '%s\n%s\n' "$old_name" "$new_name" | sort -V | tail -1)" == "$old_name" ]]; then
      echo "$new_name is lower than the current $old_name." >&2
      exit 2
    fi
    IFS=. read -r major minor patch <<<"$new_name"
    ;;
esac

next="$major.$minor.$patch+$((build + 1))"

echo "$current -> $next"
$DRY_RUN && exit 0

if $COMMIT && ! git diff --quiet -- "$PUBSPEC"; then
  echo "$PUBSPEC has uncommitted changes; commit or stash them first." >&2
  exit 1
fi

# Replace only the first `version:` line; awk keeps this portable across
# macOS and Linux sed.
tmp="$(mktemp)"
awk -v ver="$next" '
  !done && /^version:/ { print "version: " ver; done = 1; next }
  { print }
' "$PUBSPEC" >"$tmp"
# Copy back into the existing file so it keeps its permissions.
cat "$tmp" >"$PUBSPEC"
rm "$tmp"

if $COMMIT; then
  git commit --quiet -m "chore(release): v$next" -- "$PUBSPEC"
  echo "Committed chore(release): v$next"
fi

if $TAG; then
  git tag -a "v$next" -m "v$next"
  echo "Tagged v$next (push with: git push origin v$next)"
fi
