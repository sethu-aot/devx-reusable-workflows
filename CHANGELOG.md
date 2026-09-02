# Changelog

All notable changes to the DevX reusable workflows are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this repository adheres to [Semantic Versioning](https://semver.org/). Consumers
should pin to an immutable `vX.Y.Z` tag; the `vX` alias moves with each release
in that major line.

## [Unreleased]

## [1.1.1]

### Security

- **Closed a JavaScript injection in the SonarQube PR-comment step.**
  `sast-sonarqube.yaml` interpolated `sonar_project_key` and `sonar_host_url`
  straight into the `script:` body of `actions/github-script`. A GitHub
  expression is spliced into the script as text before Node parses it, so a
  project key containing a quote would have executed arbitrary JavaScript with
  a token holding `pull-requests: write`. Both values now arrive through the
  step's `env:` and are read via `process.env`. The comment call is also
  awaited, the dashboard URL is percent-encoded, and backticks in the key can
  no longer break out of the markdown code span.

  This was the same injection class already removed from every `run:` block,
  but in a different language — `script:` is not a shell script, so the earlier
  pass did not cover it.

- **`validate_workflows.py` now rejects `${{ }}` in any executable body** —
  both `run:` scripts and `actions/github-script` `script:` bodies — so neither
  form can regress. actionlint does not close this gap on its own: its
  expression-injection rule covers a fixed set of known-untrusted contexts and
  treats `inputs.*` as safe, which it is not for a reusable workflow whose
  inputs come from a caller.

### Changed

- **Split `docs/BRANCHING.md` by audience.** It described the four-stage
  deployment lifecycle (feature → dev → QA → production) as though it applied to
  this repository, which ships workflows and deploys nothing. Stages 2–4 were
  therefore unreachable here, and the `development` branch drifted 26 commits
  behind `main` as a result. The page now separates the model a *consuming
  project* should adopt from how this repository is actually maintained, where
  tagging replaces deployment. `README.md` and `CONTRIBUTING.md` updated to
  match, and `development` has been fast-forwarded to `main`.

- **Every third-party action moved to its current major.** `v1.1.0` pinned each
  action at the major already in use, so the first Dependabot run proposed the
  backlog all at once. Each bump was reviewed against its upstream breaking
  changes *and* against the inputs this repository actually passes, verified by
  fetching `action.yml` at the new commit SHA.

  | Action | From | To |
  |---|---|---|
  | `actions/checkout` | 4.4.0 | 7.0.1 |
  | `actions/setup-node` | 4.4.0 | 7.0.0 |
  | `actions/setup-python` | 5.6.0 | 7.0.0 |
  | `actions/setup-java` | 4.9.1 | 6.0.0 |
  | `actions/upload-artifact` | 4.6.2 | 7.0.1 |
  | `actions/download-artifact` | 4.3.0 | 8.0.1 |
  | `actions/github-script` | 7.1.0 | 9.0.0 |
  | `aws-actions/configure-aws-credentials` | 4.3.1 | 6.2.3 |
  | `azure/setup-helm` | 4.3.1 | 5.0.1 |
  | `docker/login-action` | 3.7.0 | 4.6.0 |
  | `docker/setup-buildx-action` | 3.12.0 | 4.3.0 |
  | `docker/build-push-action` | 5.4.0 | 7.3.0 |
  | `aquasecurity/trivy-action` | 0.24.0 | 0.36.0 |
  | `anchore/sbom-action` | 0.16.0 | 0.24.2 |
  | `bridgecrewio/checkov-action` | 12.2850.0 | 12.3122.0 |

  No documented breaking change applies to how these workflows call them:
  `download-artifact` v5 changed paths only for downloads **by ID** (this repo
  downloads by name); `github-script` v9 dropped `require('@actions/github')`
  (the script uses only the injected globals); `configure-aws-credentials` v5
  changed invalid **boolean** input handling (only strings are passed);
  `setup-buildx-action` v4 and `build-push-action` v7 removed deprecated
  inputs and envs that are not used here; `setup-node` v5 added automatic
  package-manager caching, which the explicit `cache:` input overrides.

  **Two consequences for consumers.** Most of these now run on Node 24 and
  require Actions Runner **2.327.1 or later** — irrelevant on GitHub-hosted
  runners, but self-hosted runners must be updated first.
  `docker/build-push-action` v6+ also generates a build summary and exports a
  build record artifact per build; set `DOCKER_BUILD_SUMMARY: false` to opt out.

  These bumps are static-verified only. No repository consumes these workflows
  yet, so no end-to-end pipeline run has exercised them.

## [1.1.0]

Maintainability and security hardening pass. No interface was removed or
renamed, so this is backwards compatible for existing callers.

### Fixed

- **`cd-orchestrator`: `ingress_domain` and `image_pull_secret` were always
  empty.** Both were written to `$GITHUB_OUTPUT` by the `extract` step and read
  by three downstream jobs, but neither was declared in `validate-and-load`'s
  `outputs:` map, so both resolved to `""`. EKS deployments received no image
  pull secret (`ImagePullBackOff` against private registries) and no application
  URL was produced for EKS, EC2 or the health check.
- **`cd-orchestrator`: the health check never ran after a `patch`-method EKS
  deployment.** `health-check` tested `needs.deploy-eks-patch.result` without
  listing `deploy-eks-patch` in its `needs:`, so the condition could never be
  true and the URL fallback was dead.
- **`cd-orchestrator`: the `k8s` deployment target was broken end to end.**
  `secrets.KUBECONFIG_DATA` was passed to `deploy-k8s` and `health-check` but
  never declared in `on.workflow_call.secrets`; `deploy-k8s` declared no
  workflow outputs while `needs.deploy-k8s.outputs.url` was consumed; and
  `deploy-k8s` was absent from `notify-result`, so a successful k8s deployment
  reported failure.
- **`deploy-ecs`: no `url` output** despite `cd-orchestrator` consuming
  `needs.deploy-ecs.outputs.url`, leaving the ECS health check with no target.
- **`deploy-eks` / `deploy-k8s`: image references were split on the first `:`,**
  which mis-parsed registries carrying an explicit port (`host:5000/img:tag`)
  and digest references (`img@sha256:…`).
- `cd-orchestrator`: the `k8s` branch of the config extractor did not read
  `helm.values_file` or `atomic`, so both were silently dropped.

### Security

- **Removed the shell-injection surface across all workflows.** No `run:` block
  interpolates `${{ … }}` any more; 290 expressions across 82 steps now pass
  through step-level `env:` and are read as `"$VAR"`, so a value can no longer
  be spliced into the script as code.
- **Replaced command-string construction with argv arrays** in `deploy-eks`,
  `deploy-ecs` and `deploy-k8s`. `deploy-eks` previously built a Helm command
  into a job output and re-parsed it; `deploy-ecs` used `eval`.
- **Pinned every third-party action to a full commit SHA** (63 references),
  with the version retained as a trailing comment. This removes the mutable-tag
  supply-chain risk and normalises inconsistent pinning (`@v4` vs `@v4.0.2`).
- **Replaced three actions pinned to `@master`** — `sonarqube-scan-action`,
  `sonarqube-quality-gate-action` and the deprecated `sonarcloud-github-action`
  — with pinned releases, unifying on `sonarqube-scan-action`.
- **Stopped passing the Sonar token as a command-line flag** in the Maven
  analysis step, where it was visible in `ps` output and Maven debug logs.
  `SONAR_TOKEN` was already exported for the step.
- **Pinned the Grype installer to its release tag** instead of fetching
  `install.sh` from the mutable `main` branch and piping it to `sh` as root.
- **Dropped `actions: write` from six workflows** to `actions: read`. The scope
  was justified in comments as required for artifact uploads, which is not the
  case; it also permits cancelling runs and deleting artifacts and logs.
- **Scoped `contents: write` to the `auto-merge` job alone** rather than
  granting it across the CI pipeline.
- `azure/setup-helm` moved from v3 (Node 16, end of life) to v4.
- Added `permissions:` and `timeout-minutes` to `deploy-k8s` and `auto-merge`,
  which had neither, and input validation to `auto-merge`'s `merge_method`.

### Added

- `repo-ci.yaml` — this repository now validates itself on every pull request:
  actionlint with shellcheck, the contract validator, example-config parsing,
  and a check that no real AWS account or tunnel hostname appears in `examples/`.
- `.github/scripts/validate_workflows.py` — static validation of the contracts
  *between* workflows. Catches every "Fixed" item above, all of which GitHub
  reports at run time as an empty string rather than as an error.
- `release.yaml` — cuts an immutable `vX.Y.Z` tag and moves the `vX` alias.
- `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`, `dependabot.yml`,
  `.gitignore`, `.gitattributes`, `.editorconfig`.
- `deploy-ecs`: `ingress_domain` input and a `url` output resolved from the
  service's load balancer.
- `deploy-k8s`: `helm_values_file`, `ingress_domain` and `dry_run` inputs;
  `status` and `url` outputs; chart validation and post-deploy verification.

### Changed

- **Scrubbed the public examples.** `examples/demo-*` carried a real AWS account
  ID and IAM role ARN, plus live Cloudflare-tunnel and ngrok hostnames for an
  internal Nexus, across 18 files in a public repository. All replaced with
  documented placeholders, and CI now fails if either reappears. The values
  remain in git history; the affected IAM role's OIDC trust policy should be
  reviewed and the tunnels are ephemeral and already expired.
- Added the required `permissions:` block to the Node.js and Python example
  callers, which lacked one — with a default-read token, OIDC and SARIF upload
  would have failed there while the Maven example worked.
- `demo-nodejs-app/cd.yaml`: `image_uri` is now required. It was documented as
  optional ("uses latest from Nexus if empty"), which was never implemented and
  produced a confusing mid-pipeline validation error.

### Removed

- Committed build output (`old-examples-made-for-reference/java-springboot/target/`)
  and three `*.bak` configuration files, two of which still carried the real
  AWS account ID.

## [1.0.0]

Initial release: CI and CD orchestrators driven by `devx-ci.yaml` /
`devx-config.yaml`, language build modules (Node, Python, Maven) with Nexus
upload, Docker build and push, deployment modules for EKS, ECS, EC2 and generic
Kubernetes, security scanning (Semgrep, SonarQube, Trivy, Checkov, Syft, Grype),
health checks, rollback and Google Chat notifications.

[Unreleased]: https://github.com/AOT-Technologies/devx-reusable-workflows/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/AOT-Technologies/devx-reusable-workflows/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/AOT-Technologies/devx-reusable-workflows/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/AOT-Technologies/devx-reusable-workflows/releases/tag/v1.0.0
