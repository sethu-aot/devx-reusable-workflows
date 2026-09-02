# DevX Reusable Workflows

**CI/CD Workflows for GitHub Actions**

[![Version](https://img.shields.io/github/v/tag/AOT-Technologies/devx-reusable-workflows?label=version&sort=semver)](https://github.com/AOT-Technologies/devx-reusable-workflows/releases)
[![Repo CI](https://github.com/AOT-Technologies/devx-reusable-workflows/actions/workflows/repo-ci.yaml/badge.svg)](https://github.com/AOT-Technologies/devx-reusable-workflows/actions/workflows/repo-ci.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A centralized collection of reusable GitHub Actions workflows for standardized, secure CI/CD across AOT projects.

---

## ✨ Features

- 🚀 **One Config, Full Pipeline** - Single `devx-ci.yaml` controls everything
- 🔐 **Multi-Layer Security** - SAST, IaC, container scanning, SBOM generation
- 📦 **Native Nexus Integration** - NPM, PyPI, Maven, and Docker registries
- 🐳 **Multi-Registry Docker** - Nexus, AWS ECR, GHCR, Docker Hub
- 🔄 **Language Agnostic** - Node.js, Python, Java (Maven)
- ⚡ **Optimized Builds** - Direct Nexus artifact downloads, parallel security scans

---

## 🗂️ Repository Structure

```
devx-reusable-workflows/
├── .github/workflows/          # All reusable workflows
│   ├── ci-orchestrator.yaml    # CI Brain (Builds, Tests, Scans)
│   ├── cd-orchestrator.yaml    # CD Brain (Deploys, Health Checks, Rollbacks)
│   ├── node-build.yaml         # Node.js build + NPM publish
│   ├── python-build.yaml       # Python build + PyPI publish
│   ├── maven-build.yaml        # Maven build + deploy
│   ├── docker-build.yaml       # Universal container builder
│   ├── sast-semgrep.yaml       # Static code analysis
│   ├── sast-sonarqube.yaml     # Enterprise code quality
│   ├── iac-scan.yaml           # Infrastructure scanning
│   ├── trivy-scan.yaml         # Container vulnerabilities
│   ├── sbom-generate.yaml      # SBOM generation (Syft)
│   ├── sbom-scan.yaml          # SBOM analysis (Grype)
│   ├── deploy-eks.yaml         # EKS (Helm) deployment
│   ├── deploy-ecs.yaml         # ECS deployment
│   ├── deploy-ec2.yaml         # EC2 deployment (SSM/SSH)
│   ├── deploy-k8s.yaml         # Generic K8s deployment
│   ├── health-check.yaml       # Post-deployment verification
│   ├── rollback.yaml           # Automated rollback logic
│   ├── notify-google-chat.yaml # Chat notifications
│   ├── repo-ci.yaml            # Self-validation (actionlint + contracts)
│   └── release.yaml            # Cuts vX.Y.Z tags, moves the vX alias
├── .github/scripts/
│   └── validate_workflows.py   # Cross-workflow contract validation
├── docs/                       # Documentation
├── examples/                   # Template projects
├── CONTRIBUTING.md             # Workflow authoring rules, release process
├── SECURITY.md                 # Reporting, and the properties we maintain
├── CHANGELOG.md
└── README.md
```

---

## 🚀 Quick Start

### 1. Create `devx-ci.yaml` (CI Config) & `devx-config.yaml` (CD Config)

**CI Configuration (`devx-ci.yaml`):**
```yaml
project:
  language: node
nexus:
  url: "https://nexus.example.com"
  repo_type: "npm"
docker:
  enabled: true
  registry_type: nexus
```

**CD Configuration (`devx-config.yaml`):**
```yaml
aws:
  role_to_assume: "arn:aws:iam::123:role/GHA"
deployment:
  enabled: true
  target: "eks"
  environments:
    dev:
      enabled: true
      cluster_name: "dev-cluster"
```

### 2. Create Workflow Files

> **Pin to an immutable tag.** The examples below use `@v1`, which is a *moving*
> alias for the latest `v1.x.y` release. That is fine while you are getting
> started; for production repositories reference a specific release such as
> `@v1.1.0` so an upstream change can never alter your pipeline without a PR.
> See [Versioning](#-versioning).

**CI Pipeline (`.github/workflows/ci.yaml`):**
```yaml
uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/ci-orchestrator.yaml@v1
with:
  config_path: devx-ci.yaml
secrets: inherit
```

**CD Pipeline (`.github/workflows/cd.yaml`):**
```yaml
uses: AOT-Technologies/devx-reusable-workflows/.github/workflows/cd-orchestrator.yaml@v1
with:
  environment: dev
  image_uri: ${{ needs.ci.outputs.image_uri }}
secrets: inherit
```

### 3. Add Secrets

- `NEXUS_USERNAME` / `NEXUS_PASSWORD`
- `GOOGLE_CHAT_WEBHOOK` (Optional)

**That's it!** Push to main to trigger CI, then deploy to Dev.

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [docs/README.md](docs/README.md) | Main documentation hub |
| [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) | CI setup guide |
| [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | **CD / Deployment setup guide** |
| [docs/CONFIG_REFERENCE.md](docs/CONFIG_REFERENCE.md) | CI configuration options |
| [docs/CD_CONFIG_REFERENCE.md](docs/CD_CONFIG_REFERENCE.md) | **CD configuration options** |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical deep dive (CI/CD) |
| [docs/ROLLBACK_PROCEDURES.md](docs/ROLLBACK_PROCEDURES.md) | Rollback strategies |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | CI troubleshooting |
| [docs/CD_TROUBLESHOOTING.md](docs/CD_TROUBLESHOOTING.md) | CD troubleshooting |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Authoring rules, validation, release process |
| [SECURITY.md](SECURITY.md) | Reporting a vulnerability, security properties |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

---

## 📦 Examples

| Example | Description |
|---------|-------------|
| [examples/demo-nodejs-app/](examples/demo-nodejs-app/) | Node.js Express API with Docker |
| [examples/demo-maven-app/](examples/demo-maven-app/) | Maven with Nexus |
| [examples/demo-python-app/](examples/demo-python-app/) | Python with PyPI |


---

## ⚙️ Supported Technologies

| Category | Options |
|----------|---------|
| **Languages** | Node.js, Python, Java (Maven) |
| **Artifact Repos** | Nexus (NPM, PyPI, Maven, Raw) |
| **Container Registries** | Nexus Docker, AWS ECR, GHCR, Docker Hub |
| **Deployment Targets** | **AWS EKS**, **AWS ECS**, **AWS EC2**, **Generic K8s** |
| **Security Scanning** | Semgrep, SonarQube, Checkov, Trivy, Syft, Grype |

---

## 🔐 Security

Scan results upload to **GitHub Security → Code scanning alerts**:

| Category | Tool | Gates the pipeline? |
|----------|------|---------------------|
| `sast-semgrep` | Semgrep | Yes, when `fail_on_findings` is true (default) |
| `iac-checkov` | Checkov | Yes, unless `soft_fail` is set |
| `trivy-image` | Trivy | Yes, when `fail_on_vuln` is true (default) |
| `sbom-grype` | Grype | **No — report only.** `sbom-scan` never fails the pipeline by design; use `trivy` for enforcement. |

The workflows themselves are built to hold a set of security properties — no
shell injection surface, SHA-pinned third-party actions, least-privilege tokens,
OIDC instead of stored AWS keys. These are enforced in CI by
`.github/scripts/validate_workflows.py`; see [SECURITY.md](SECURITY.md) for the
full list and how to report a problem.

---

## 🏷️ Versioning

This repository is versioned as a whole, following [Semantic Versioning](https://semver.org/).

- **`@v1.1.0`** — an immutable release tag. Use this in production repositories.
- **`@v1`** — a moving alias for the latest `v1.x.y`. Convenient, but it means
  an upstream release changes your pipeline without a PR.
- **`@main`** — never use this.

Breaking changes to any `workflow_call` interface get a new major version and a
new alias. Release history is in [CHANGELOG.md](CHANGELOG.md); the process is in
[CONTRIBUTING.md](CONTRIBUTING.md#releases).

---

## 🏷️ GitHub Branching Strategy

The model DevX recommends for a **consuming project repository**:

- `main` — production-ready code only.
- `development` — integration branch for new features. CD triggers here for dev/qa environments.
- `feature/*` — individual work branches linked to Jira tickets.

This repository is maintained differently: it ships workflows rather than a
deployable application, so it has no environments and releases via tags instead.
[docs/BRANCHING.md](docs/BRANCHING.md) documents both.

---
## 🤝 Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a PR. In short: run
`actionlint` and `python .github/scripts/validate_workflows.py` locally, never
interpolate `${{ … }}` into a `run:` block, and pin third-party actions to a
commit SHA.

---

## 📄 License

MIT License — see [LICENSE](LICENSE).