<!--
Every workflow here is called by other repositories, and there is no staging
environment between `main` and their production pipelines. Please fill this in.
-->

## What changed and why

<!-- One or two sentences. Link the Jira ticket or issue. -->

## Interface impact

- [ ] No change to any `workflow_call` input, secret or output
- [ ] Added an optional input with a default (backwards compatible)
- [ ] **Breaking** — renamed/removed an input, made one required, or changed
      what an output contains. Needs a major version; see
      [CONTRIBUTING.md](../CONTRIBUTING.md#changing-an-interface).

## Verification

<!--
A workflow change cannot be verified by reading it. Say what you actually ran.
-->

- [ ] `actionlint` passes locally
- [ ] `python .github/scripts/validate_workflows.py` passes locally
- [ ] For a behavioural change: link to a real pipeline run that exercised the
      changed path → <!-- paste run URL -->

## Security checklist

<!-- See SECURITY.md for why each of these matters. -->

- [ ] No `${{ … }}` interpolated into a `run:` block — values go through `env:`
      and are read as `"$VAR"`
- [ ] Commands built as argv arrays, not assembled into strings and `eval`'d
      (except inputs that are commands by definition, marked with a comment)
- [ ] Any new third-party action is pinned to a full 40-character commit SHA
      with the version as a trailing comment
- [ ] Any new `permissions:` scope is the least that works, and elevated scopes
      are set on the single job that needs them
- [ ] Secrets are passed via `env:`, never as command-line flags
- [ ] New jobs set `timeout-minutes`
- [ ] No real account IDs, role ARNs, hostnames or credentials added to
      `examples/` or `docs/`

## Changelog

- [ ] Added an entry under `## [Unreleased]` in [CHANGELOG.md](../CHANGELOG.md)
