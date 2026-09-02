# 🏷️ GitHub Branching Strategy

This page covers two different things. Read the one you need:

1. **[For consuming project repositories](#part-1-for-consuming-project-repositories)** —
   the branching model an application repo should adopt to get the full
   four-stage DevX lifecycle (feature → dev → QA → production).
2. **[For this repository](#part-2-for-this-repository-devx-reusable-workflows)** —
   how `devx-reusable-workflows` itself is maintained. It ships workflows rather
   than an application, so it has no environments and no deployment stages.

> These were previously described as a single model, which is why the
> `development` branch here drifted 26 commits behind `main`: stages 2–4 below
> have no meaning for a repository that deploys nothing.

---

# Part 1: For consuming project repositories

The model below is what an application repository using the DevX workflows
should follow.

## 🌳 Branch Hierarchy

| Branch | Purpose | Permissions |
| :--- | :--- | :--- |
| **`main`** | **Production-ready code.** Reflects the current state of QA and Production. | **Protected**. No direct pushes. |
| **`development`** | **Integration branch.** Where all features are merged for testing. | **Protected**. PR required from feature branches. |
| **`feature/*`** | **Active development.** Short-lived branches for specific Jira tickets. | Open. Pushed by individual developers. |

## ⚙️ Branch Protection

Set these on `development` and `main`. (Branch protection on a private
repository requires a paid GitHub plan; public repositories get it free.)

### 🛡️ Development Branch Protection
1.  **Branch name pattern**: `development`
2.  **Protect matching branches**:
    -   Check **"Require a pull request before merging"**.
    -   Check **"Require status checks to pass before merging"**.
    -   Search for and select: **`DevX CI Pipeline`** — this is the name of the
        job in your `ci.yaml` that calls `ci-orchestrator.yaml`, so it matches
        whatever you named that job.

### 🛡️ Main Branch Protection
1.  **Branch name pattern**: `main`
2.  **Protect matching branches**:
    -   Check **"Require a pull request before merging"** (Development ➡️ Main).
    -   Check **"Require status checks to pass before merging"**.

## 🔄 Deployment Lifecycle (4-Stage Flow)

### Stage 1: Feature Build (Verification)
-   **Trigger**: Create Pull Request from `feature/*` ➡️ `development`.
-   **Action**: Runs **CI Only** (Build, Test, Security). No deployment.
-   **Goal**: Ensure code is safe to merge.

### Stage 2: Dev Build (Integration)
-   **Trigger**: Merge Pull Request into `development`.
-   **Action**: Runs **CI + CD to Dev Environment**.
-   **Goal**: Test interactions in a shared dev environment.

### Stage 3: QA Build (Release Candidate)
-   **Trigger**: Merge `development` ➡️ `main`.
-   **Action**: Runs **CI + CD to QA Environment**.
-   **Goal**: Create a "Golden Image" for final sign-off.

### Stage 4: Production Deployment (Promotion)
-   **Trigger**: **Manual trigger** on the `main` branch.
-   **Action**: **CD Only** (Deploys the image built in Stage 3).
-   **Goal**: Zero-recompile promotion from QA to Production.

## 🚀 Step-by-Step for Developers

1.  **Start Work**: Jira ticket moves to "In Progress" ➡️ Auto-create `feature/DEV-123-ticket-name`.
2.  **Push Code**: `git push origin feature/DEV-123-ticket-name`.
3.  **Propose Changes**: Open PR to `development`.
4.  **Verify**: Wait for the **DevX CI Pipeline** status check to turn green.
5.  **Integrate**: Click **Merge**. Your changes now automatically deploy to the **Dev Server**!

---

# Part 2: For this repository (`devx-reusable-workflows`)

This repository produces reusable workflows, not a deployable artifact. There is
no dev server, no QA environment and no production promotion, so Stages 2–4
above do not apply. What replaces them is **tagging**: a release here is a git
tag that consuming repositories pin to.

## 🌳 Branches

| Branch | Purpose | Permissions |
| :--- | :--- | :--- |
| **`main`** | **Released code.** What the `vX` alias points at. | **Protected**. PR required. |
| **`development`** | **Integration branch.** Kept in sync with `main`; used to batch several changes before a release. | **Protected**. PR required. |
| **`feature/*`** | Short-lived branches for a specific Jira ticket or fix. | Open. |

A single self-contained change may PR straight into `main`. Use `development`
when several changes need to be integrated and reviewed together before a
release.

`development` must never fall behind `main`. After anything merges to `main`,
fast-forward it — no force needed, since `development` has no unique commits:

```bash
git push origin origin/main:refs/heads/development
```

## 🛡️ Branch Protection for this repository

The `DevX CI Pipeline` check in Part 1 does **not** apply here — this repository
does not run the DevX pipeline on itself, it validates its own workflows.
Require these checks instead, from
[repo-ci.yaml](../.github/workflows/repo-ci.yaml):

- `Lint workflows`
- `Validate workflow contracts`
- `Validate example configs`

Also enable **"Require review from Code Owners"** on `main`, backed by
[.github/CODEOWNERS](../.github/CODEOWNERS). Every file here is consumed by
other repositories, so an unreviewed change reaches all of them at once.

## 🏷️ Release Lifecycle

This replaces the four deployment stages. See
[CONTRIBUTING.md](../CONTRIBUTING.md#releases) for the full process.

| Stage | Trigger | Action |
| :--- | :--- | :--- |
| **1. Verify** | PR from `feature/*` | `repo-ci` runs actionlint, contract validation and example checks. No release. |
| **2. Integrate** | Merge to `development` or `main` | `repo-ci` re-runs on the merged result. Still no release — `main` moving does not change what consumers get. |
| **3. Release** | Manual run of [release.yaml](../.github/workflows/release.yaml) | Creates an immutable `vX.Y.Z` tag and moves the `vX` alias. Refuses to run unless `repo-ci` is green on the commit and the version appears in `CHANGELOG.md`. |

Consumers pin to `vX.Y.Z`, so merging to `main` is safe: nothing reaches a
consuming pipeline until a release is cut and the `vX` alias moves.
