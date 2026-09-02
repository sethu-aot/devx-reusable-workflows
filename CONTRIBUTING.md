# Contributing

Every workflow in this repository is called by other repositories. There is no
staging environment between `main` and production pipelines across the
organisation, so the review bar is higher than for an application repository.

## Before you start

```bash
git clone https://github.com/AOT-Technologies/devx-reusable-workflows.git
cd devx-reusable-workflows
pip install pyyaml
```

Install [actionlint](https://github.com/rhysd/actionlint) and
[shellcheck](https://www.shellcheck.net/) — CI runs both, and running them
locally is much faster than a round trip through a PR.

## Checks

Run both before pushing. They are the same checks CI runs.

```bash
actionlint && python .github/scripts/validate_workflows.py
```

`actionlint` validates each workflow in isolation: schema, expression syntax,
unknown contexts, and (via shellcheck) the `run:` scripts.

`validate_workflows.py` validates the relationships *between* workflows — the
failures GitHub reports as an empty string at run time rather than as an error:

- every `needs.<job>` reference is a declared dependency
- every consumed job output is declared in that job's `outputs:` map
- `with:` / `secrets:` match the callee's declaration, required inputs are
  supplied, and every consumed workflow output exists on the callee
- every `secrets.X` used is declared in `on.workflow_call.secrets`
- no third-party action is on a mutable tag or branch
- every reusable module declares a top-level `permissions:` block
- no `${{ }}` appears inside a `run:` script or a `github-script` `script:` body

## Rules for workflow code

These are not style preferences. Each one exists because its absence has a
specific failure mode; see [SECURITY.md](SECURITY.md#security-properties-these-workflows-are-built-to-hold).

**Never interpolate `${{ … }}` into anything that is executed as code** — a
`run:` block, or the `script:` body of `actions/github-script`. Pass the value
through step-level `env:` and read it as `"$VAR"` in shell or
`process.env.VAR` in JavaScript. A GitHub expression is spliced in textually
before bash or Node parses it, so any metacharacter in the value is executed.
An environment variable is data. The validator rejects both cases.

```yaml
# no
- run: helm upgrade ${{ inputs.release }} ${{ inputs.chart }}

# yes
- env:
    RELEASE: ${{ inputs.release }}
    CHART: ${{ inputs.chart }}
  run: helm upgrade "$RELEASE" "$CHART"
```

```yaml
# no  -- a project key containing a quote executes arbitrary JavaScript
- uses: actions/github-script@<sha> # v9
  with:
    script: const key = '${{ inputs.project_key }}';

# yes
- uses: actions/github-script@<sha> # v9
  env:
    PROJECT_KEY: ${{ inputs.project_key }}
  with:
    script: const key = process.env.PROJECT_KEY ?? '';
```

**Build commands as argv arrays, never as strings.** Assembling a command into a
variable and running it with `eval` — or leaving it unquoted — re-parses every
value as shell syntax.

```yaml
run: |
  ARGS=(upgrade --install "$RELEASE" "$CHART" --namespace "$NAMESPACE")
  [[ "$ATOMIC" == "true" ]] && ARGS+=(--atomic)
  helm "${ARGS[@]}"
```

The one exception is an input that *is* a command by definition
(`build_script`, `test_script`, `install_command`). Mark it with a comment
saying so.

**Pin third-party actions to a full commit SHA**, with the version as a
trailing comment. Dependabot moves both together.

```yaml
uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4
```

For downloaded binaries, pin the version and verify a checksum.

**Declare `permissions:` on every workflow**, at the least privilege that works.
Put elevated scopes on the single job that needs them, not workflow-wide.

**Set `timeout-minutes` on every job.** The default is 6 hours of billed runner
time on a hang.

**Declare every job output you consume.** Writing `foo=bar` to `$GITHUB_OUTPUT`
does nothing on its own — the value is only visible to other jobs if `foo`
appears in the job's `outputs:` map. Omitting it yields an empty string with no
error, which is why the validator checks for it.

**Start `run:` blocks with `set -euo pipefail`** unless the step deliberately
tolerates failures, in which case use `set -uo pipefail` and handle exit codes
explicitly.

## Changing an interface

Adding an optional input with a default is backwards compatible. Anything else
is not:

- renaming or removing an input, secret or output
- making an optional input required
- changing an input's default in a way that changes behaviour
- changing what an output contains

A breaking change needs a major version. Add the new input alongside the old
one, mark the old one deprecated in its `description:`, and remove it in the
next major.

## Releases

Consumers pin to an immutable tag; the `vN` alias exists for convenience and
moves.

```bash
# after the change is merged to main and CI is green
git checkout main && git pull
git tag -a v1.3.0 -m "Add ingress_domain support to deploy-ecs"
git push origin v1.3.0

# move the major alias to the same commit
git tag -fa v1 -m "v1 -> v1.3.0"
git push origin v1 --force
```

Version the repository as a whole, not per workflow — the orchestrators call the
modules by tag, so the set has to move together.

| Change | Bump |
|---|---|
| Breaking interface change (see above) | major — `v2.0.0`, and start a `v2` alias |
| New workflow, new optional input, new output | minor — `v1.3.0` |
| Bug fix, action SHA bump, docs | patch — `v1.2.4` |

Record every release in [CHANGELOG.md](CHANGELOG.md) before tagging.

## Pull requests

- Branch as `feature/<jira-ticket>` and open a PR. A single self-contained
  change can target `main` directly; use `development` when several changes need
  to be integrated and reviewed together before a release. Neither `main` nor
  `development` accepts direct pushes. See
  [docs/BRANCHING.md](docs/BRANCHING.md#part-2-for-this-repository-devx-reusable-workflows)
  — note that the four-stage deploy flow described there applies to *consuming*
  project repositories, not to this one.
- After anything merges to `main`, fast-forward `development` so it cannot drift:
  `git push origin origin/main:refs/heads/development`.
- Use [Conventional Commits](https://www.conventionalcommits.org/) — the
  changelog is grouped by type.
- Say in the description what you ran to verify. "actionlint and the validator
  pass" is the minimum; for a behavioural change, link a real pipeline run in a
  test repository that exercised the changed path.
- A workflow change cannot be verified by reading it. If you changed a `run:`
  block, run it.
