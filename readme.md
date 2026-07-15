#  OIDC GitHub Actions Role for AWS

![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-IAM%20%2F%20STS-FF9900?logo=amazon-aws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub-Actions%20OIDC-2088FF?logo=githubactions&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)

>  Spin up a secure, keyless **AWS IAM Role** trusted by **GitHub Actions OIDC** in seconds — no long-lived AWS access keys stored in GitHub secrets.

---

##  What This Does

This repo automates the AWS side of the [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) setup:

-  Creates the GitHub OIDC Identity Provider in your AWS account (if it doesn't exist yet)
-  Creates an IAM Role (`GitHubActionsRole-<repo>`) trusted by your specific GitHub repository
-  Attaches an inline permission policy (`GitHubActionsPolicy-<repo>`) so your workflow can deploy
-  Prints the Role ARN, ready to paste into your GitHub Actions workflow

---

##  Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured (`aws configure`) with credentials that can create IAM roles/policies and an OIDC provider.
- `openssl` and `curl` available on your machine (already present on macOS/Linux by default).
- Your GitHub username and the name of the repository you want to trust.

---

##  Step-by-Step: How To Run

### 1. Set your GitHub username

```bash
export GIT_HUB_USER_NAME="github-user-example"
```

### 2. Add a `permission-policy.json` to your project

In the root of the project you want to deploy from GitHub Actions, create a `permission-policy.json` file. Use the [example in this repo](./oidc/permission-policy.json) as a starting point and **scope it down** to only the AWS actions your workflow actually needs.

### 3. Run the script

You have two ways to run it, depending on where the script lives relative to your project.

**Option A — remote (from your project's root folder):**

```bash
curl -s https://raw.githubusercontent.com/rafaelhueb92/oidc-github-actions-role-aws/refs/heads/master/oidc/create-role.sh | bash
```

This uses the current folder name as the repository name, so run it from the root of the repository you want to trust.

**Option B — local (script cloned inside the `oidc/` subfolder of your project):**

```bash
cd oidc
bash create-role-local.sh
```

`create-role-local.sh` derives the repository name from the parent folder, so it expects to sit in an `oidc/` subdirectory of your project.

Both scripts will:
1. Look up your AWS account ID.
2. Create the GitHub OIDC provider in AWS (skipped if it already exists).
3. Create the trust policy from `trust-policy.json`, filling in your AWS account ID and `GITHUB_USER/REPO`.
4. Create the IAM role `GitHubActionsRole-<repo>`.
5. Attach `permission-policy.json` as an inline policy on that role.
6. Print the resulting Role ARN.

### 4. Copy the Role ARN into your GitHub Actions workflow

Use the printed ARN with the [`aws-actions/configure-aws-credentials`](https://github.com/aws-actions/configure-aws-credentials) action, e.g.:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<account-id>:role/GitHubActionsRole-<repo>
    aws-region: us-east-1
```

### 5. Need to update the permissions later?

Edit `permission-policy.json`, then re-run:

```bash
curl -s https://raw.githubusercontent.com/rafaelhueb92/oidc-github-actions-role-aws/refs/heads/master/oidc/update-role.sh | bash
```

This re-applies the policy file to the existing role without touching the OIDC provider or trust policy.

---

##  Is It Safe to Run?

**Not blindly, no — and that's true of any `curl | bash` command.** Here's an honest breakdown before you run this against a real AWS account:

| Aspect | Assessment |
|---|---|
| **`curl \| bash` pattern** | ⚠️ Executes remote code straight from `master` with no version pinning, checksum, or review step. If the script content changes (or the repo/account is ever compromised), you'd run whatever is there at the time — classic supply-chain risk. |
| **OIDC trust design** | ✅ The core idea is solid and is AWS's recommended pattern — it avoids storing static AWS access keys in GitHub, using short-lived, per-repo scoped credentials instead. |
| **Trust policy scope** | ⚠️ `trust-policy.json` hardcodes `ref:refs/heads/main`, so make sure your default branch really is `main` and that you don't widen this to `repo:ORG/REPO:*` (which would let *any* branch/PR/tag assume the role). |
| **`permission-policy.json` example** | 🔴 The bundled example is **overly broad for production use** — it includes `iam:*`, `lambda:*`, `ssm:*`, `sts:AssumeRole` on `"Resource": "*"`. `iam:*` in particular is a privilege-escalation risk: a compromised workflow could create/attach new roles and policies, or escalate its own permissions. |
| **Least privilege** | 🔴 As shipped, the policy is meant as a *template*, not a safe default. Anyone using it as-is grants their CI far more power than most deployments need. |
| **Local temp files** | ✅ `trust-policy-temp.json` is git-ignored, so no leaked account IDs from local runs. |

###  Recommendations

- Treat this as an **OIDC bootstrap tool / educational template**, not a drop-in production-ready security tool.
- Scope down `permission-policy.json` per project (remove the `iam:*`, `lambda:*`, `ssm:*` wildcards and `Resource: "*"`).
- Pin the script to a specific git tag/commit SHA instead of `master` when running `curl | bash` against your own AWS accounts.
- Make sure the trust policy's `sub` condition matches the **exact branch/environment** you intend to trust.

---

##  Repo Structure

```
oidc/
├── create-role.sh          # Create OIDC provider + role (curl | bash usage)
├── create-role-local.sh    # Same, but for running locally from within the oidc/ folder
├── update-role.sh          # Update the permission policy on an existing role
├── trust-policy.json        # OIDC trust policy template
└── permission-policy.json   # Example IAM permissions (⚠️ scope this down!)
```
