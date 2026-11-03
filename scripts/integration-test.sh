#!/usr/bin/env bash
# Installs the shard as a real dependency in spec/integration/consumer and
# asserts the rule reports only the over-limit method.
#
# This is the check the in-repo CI steps cannot make: they require the rule by
# relative path, so they never exercise shard.yml, dependency resolution or the
# public require path a consumer actually uses.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
consumer="$root/integration/consumer"

cd "$consumer"

shards install

# The consumer requires "ameba-method_length", resolved from lib/.
crystal build bin/ameba.cr -o bin/ameba

fail=0

assert_contains() {
  local out="$1" expected="$2" desc="$3"
  if grep -qF "$expected" <<<"$out"; then
    echo "ok: $desc"
  else
    echo "FAIL: $desc"
    echo "expected to find: $expected"
    echo "actual output:"
    echo "$out"
    fail=1
  fi
}

assert_not_contains() {
  local out="$1" unexpected="$2" desc="$3"
  if grep -qF "$unexpected" <<<"$out"; then
    echo "FAIL: $desc"
    echo "did not expect to find: $unexpected"
    echo "actual output:"
    echo "$out"
    fail=1
  else
    echo "ok: $desc"
  fi
}

assert_contains "$(./bin/ameba --no-color --rules)" \
  "Metrics/MethodLength" \
  "rule is registered when required as a dependency"

output="$(./bin/ameba --no-color --only Metrics/MethodLength src 2>&1 || true)"

assert_contains "$output" "src/bad.cr:" "over-limit method is reported"
assert_contains "$output" "Method is too long [6/5 lines]" "issue message uses configured MaxLines"
assert_not_contains "$output" "src/ok.cr:" "method at the limit is not reported"
assert_not_contains "$output" "src/folded.cr:" "CountAsOne folds a multi-line array"
assert_not_contains "$output" "src/allowed.cr:" "AllowedMethods exempts a long method"

exit "$fail"
