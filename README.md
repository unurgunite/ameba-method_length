# ameba-method_length

An [Ameba](https://github.com/crystal-ameba/ameba) rule that reports methods longer than a configurable number of
lines — the Crystal counterpart of RuboCop's `Metrics/MethodLength`.

## Why a shard

Ameba has no plugin API: rules are registered at compile time, so a third-party rule has to be `require`d into the same
binary as the Ameba CLI. Requiring this shard from your own `bin/ameba.cr` is that hook.

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
```

| Property    | Default | Meaning                                              |
|-------------|---------|------------------------------------------------------|
| `MaxLines`  | `15`    | Maximum number of lines a method may occupy.         |
| `Enabled`   | `true`  | Toggle the rule.                                     |
| `Excluded`  | —       | Standard Ameba `Excluded` globs.                     |

## Line counting

Lines are counted from the `def` line to the closing `end`, both inclusive:

```crystal
def hello    # 1
  a = 1      # 2
  a          # 3
end          # 4  → reported as [4/3 lines] when MaxLines: 3
```

Multi-line literals and heredocs count every physical source line; there is no `CountAsOne` equivalent yet.
`abstract def` and other bodyless declarations have no end location and are never reported.

## Running the specs

```bash
shards install
crystal spec
crystal tool format --check src spec bin
crystal run bin/ameba.cr --
```

## License

MIT
