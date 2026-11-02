# ameba-method_length

An [Ameba](https://github.com/crystal-ameba/ameba) rule that reports methods longer than a configurable number of
lines — the Crystal counterpart of RuboCop's `Metrics/MethodLength`.

## Why a shard

Ameba has no plugin API: rules are registered at compile time, so a third-party rule has to be `require`d into the same
binary as the Ameba CLI. Requiring this shard from your own `bin/ameba.cr` is that hook.

* [ameba-method_length](#ameba-method_length)
    * [Why a shard](#why-a-shard)
    * [Installation](#installation)
    * [Wiring](#wiring)
    * [Configuration](#configuration)
    * [Line counting](#line-counting)
    * [Running the specs](#running-the-specs)
    * [Integration test](#integration-test)
    * [License](#license)

## Installation

Add the shard as a development dependency:

```yaml
# shard.yml
development_dependencies:
  ameba:
    github: crystal-ameba/ameba
    version: "1.7.0"
  ameba-method_length:
    github: unurgunite/ameba-method_length
```

```bash
shards install
```

## Wiring

Create (or edit) `bin/ameba.cr` in your project:

```crystal
require "ameba/cli"
require "ameba-method_length"
```

Then run Ameba through that file instead of a prebuilt binary:

```bash
crystal run bin/ameba.cr --
```

To get a reusable binary, add a target and build it:

```yaml
# shard.yml
targets:
  ameba:
    main: bin/ameba.cr
```

```bash
shards build ameba
./bin/ameba
```

Without this wiring the rule is not in the binary and Ameba will not see it.

## Configuration

```yaml
# .ameba.yml
Metrics/MethodLength:
  Enabled: true
  MaxLines: 15
  CountAsOne:
    - array
    - hash
    - heredoc
  ExcludeLimit: false
  IgnoreComments: false
  AllowedMethods:
    - initialize
```

| Property         | Default | Meaning                                                                 |
|------------------|---------|-------------------------------------------------------------------------|
| `MaxLines`       | `15`    | Maximum number of lines a method may occupy.                            |
| `CountAsOne`     | `[]`    | Multi-line literals folded into one counted line: `array`, `hash`, `heredoc`. |
| `ExcludeLimit`   | `false` | Excludes the `def` line itself from the count.                          |
| `IgnoreComments` | `false` | Comment-only lines are not counted.                                     |
| `AllowedMethods` | `[]`    | Method names exempt from the rule, e.g. a long `initialize`.            |
| `Enabled`        | `true`  | Toggle the rule.                                                        |
| `Excluded`       | —       | Standard Ameba `Excluded` globs.                                        |

An unknown `CountAsOne` value aborts config loading with an `ArgumentError` rather than silently counting wrong.

## Line counting

Lines are counted from the `def` line to the closing `end`, both inclusive:

```crystal
def hello    # 1
  a = 1      # 2
  a          # 3
end          # 4  → reported as [4/3 lines] when MaxLines: 3
```

Multi-line literals and heredocs count every physical source line unless listed in `CountAsOne`.
`abstract def` and other bodyless declarations have no end location and are never reported.

```crystal
def hello        # 1
  a = [          # 2 → 2 with CountAsOne: [array]
    1,           # 3 → 2
  ]              # 4 → 2
end              # 5
```

## Development

```bash
shards install
crystal spec
crystal tool format --check src spec bin
crystal run bin/ameba.cr --                                  # lint
crystal run lib/catalyst/src/catalyst.cr -- --ci src bin      # performance analysis
```

`ameba` and `catalyst` are development dependencies: they are not pulled in by consumers of this shard.
Catalyst reports no binary target, so its entrypoint is run straight from `lib/`. `--ci` makes it exit non-zero on
any finding.

## Integration test

`integration/consumer/` is a throwaway project that depends on this shard through `shard.yml` and requires it the
way a user would. `scripts/integration-test.sh` runs `shards install` there, builds the consumer's `bin/ameba.cr`, and
asserts that a method at the configured limit is not reported while one over it is.

```bash
./scripts/integration-test.sh
```

This is the only check that exercises dependency resolution and the public `require "ameba-method_length"` path.

## Releasing

A shard ships as a git tag: consumers pin `version: X.Y.Z` and `shards install` resolves the tag itself, so there is no
binary to build or attach. Run the **Release** workflow manually with the version you want to publish:

1. Bump `version` in `shard.yml` and `VERSION` in `src/ameba/method_length/version.cr` to the same value, and land that
   change first — the workflow refuses to tag when the two disagree with each other or with the input.
2. Merge the release branch into `master` with a merge commit.
3. Run **Release** from `master` with that version. It re-runs the specs and the integration test, then creates the tag
   and the GitHub release with generated notes. It fails if the release already exists.

Branch protection and the "PRs to `master` only from `v*` or `system/*`" check come from
[`FlorexLabs/shared-workflows`](https://github.com/FlorexLabs/shared-workflows), referenced rather than copied.

## License

MIT
