## Description

What does this PR do?

## Reproduction

Minimal Crystal code that triggers the rule:

```crystal
# Example
```

## Expected output

```
# ameba output
```

## Checklist

- [ ] Tests pass (`crystal spec`)
- [ ] Formatting clean (`crystal tool format --check src spec bin`)
- [ ] Lint clean (`crystal run bin/ameba.cr --`)
- [ ] Rule still loads from `bin/ameba.cr` (`crystal run bin/ameba.cr -- --rules`)
- [ ] Branch name follows convention (`feature/*`)
- [ ] Version bumped (`shard.yml` + `src/ameba/method_length/version.cr`) if this is a release
