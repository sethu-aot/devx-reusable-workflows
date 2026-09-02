# Security Policy

This repository holds the CI/CD workflows used across AOT Technologies. A defect
here reaches every consuming repository at once, and the workflows run with
credentials that can push images and deploy to production. Please treat findings
accordingly.

## Reporting a vulnerability

**Do not open a public issue for a security problem.**

Report privately through GitHub's [private vulnerability reporting][pvr] on this
repository (Security → Report a vulnerability), or email
`devops@aot-technologies.com` with:

- the workflow file and, if known, the job or step involved
- what an attacker could achieve, and what access they would need to start
- a reproduction or proof of concept if you have one

We aim to acknowledge within 2 business days and to ship a fix or a documented
mitigation within 14 days for anything that permits credential disclosure,
arbitrary command execution, or an unauthorised deployment.

[pvr]: https://docs.github.com/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability

## Scope

In scope:

- anything under `.github/workflows/` and `.github/scripts/`
- the example configurations under `examples/`, where a copied-and-pasted
  insecure default is itself the vulnerability
- documentation that instructs users to configure something unsafely

Out of scope: vulnerabilities in the third-party actions and tools these
workflows invoke. Report those upstream; open an issue here so we can pin away
from the affected version.

## Security properties these workflows are built to hold

Changes must not weaken any of these. `.github/scripts/validate_workflows.py`
enforces the mechanical ones in CI.

| Property | How it is maintained |
|---|---|
| No untrusted value reaches an interpreter as code | `${{ … }}` is never interpolated into a `run:` block or into an `actions/github-script` `script:` body. Values pass through step-level `env:` and are read as `"$VAR"` in shell or `process.env.VAR` in JavaScript, so metacharacters stay data. Enforced by `validate_workflows.py`. |
| No command strings | Commands are built as bash argv arrays, never assembled as strings and re-parsed with `eval`. The exception is the consumer's own `build_script` / `test_script` / `install_command`, which are commands by definition and are marked as such. |
| Immutable third-party code | Every third-party action is pinned to a full 40-character commit SHA with the version in a trailing comment. Tags and branches are mutable and are rejected by CI. Downloaded binaries are pinned by version and verified by checksum. |
| Least privilege | Every workflow declares a top-level `permissions:` block. Elevated scopes (`contents: write`, `packages: write`) are set on the single job that needs them, not workflow-wide. |
| No long-lived cloud credentials | AWS access uses OIDC role assumption (`id-token: write`), never stored access keys. |
| Secrets stay out of process arguments | Tokens are passed through `env:`, never as command-line flags where they appear in `ps` output and debug logs. |

## Guidance for consuming repositories

- **Pin to an immutable tag.** Reference `@v1.2.3`, not `@v1` or `@main`. The
  `v1` alias moves; a patch release does not. See [CONTRIBUTING.md](CONTRIBUTING.md#releases).
- **Scope your `GITHUB_TOKEN`.** A reusable workflow can never hold more
  permission than its caller. Grant only what your pipeline uses; the examples
  under `examples/` show a working minimum.
- **Prefer `secrets:` over `secrets: inherit`.** `inherit` hands every
  repository secret to the called workflow. Name the secrets you actually need.
- **Constrain the OIDC trust policy.** The IAM role's trust condition must pin
  `token.actions.githubusercontent.com:sub` to your specific repository *and*
  ref — for example `repo:AOT-Technologies/my-app:ref:refs/heads/main`. A
  wildcard `sub`, or one scoped only to the organisation, lets any repository
  that can reach your account assume the role. See [docs/AWS_OIDC.md](docs/AWS_OIDC.md).
- **Never commit real account IDs, role names, registry hostnames, or
  kubeconfigs** to a public repository, including in example configuration.
