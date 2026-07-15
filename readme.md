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

##  How To Use

### 1️⃣ Set your GitHub username

```bash
export GIT_HUB_USER_NAME="github-user-example"
```

### 2️⃣ Run it in your project folder

```bash
curl -s https://raw.githubusercontent.com/rafaelhueb92/oidc-github-actions-role-aws/refs/heads/master/oidc/create-role.sh | bash
```

>  Make sure a `permission-policy.json` file exists in the same folder — use the [example in this repo](./oidc/permission-policy.json) as a starting point and scope it down to what your workflow actually needs.

### 🔄 Need to update the permissions later?

```bash
curl -s https://raw.githubusercontent.com/rafaelhueb92/oidc-github-actions-role-aws/refs/heads/master/oidc/update-role.sh | bash
```

---

##  Is It Safe to Run?

**Not blindly, no — and that's true of any `curl | bash` command.** Here's an honest breakdown before you post this or run it against a real AWS account:

| Aspect | Assessment |
|---|---|
| **`curl \| bash` pattern** | ⚠️ Executes remote code straight from `master` with no version pinning, checksum, or review step. If the script content changes (or the repo/account is ever compromised), you'd run whatever is there at the time — classic supply-chain risk. |
| **OIDC trust design** | ✅ The core idea is solid and is AWS's recommended pattern — it avoids storing static AWS access keys in GitHub, using short-lived, per-repo scoped credentials instead. |
| **Trust policy scope** | ⚠️ `trust-policy.json` hardcodes `ref:refs/heads/main`, so make sure your default branch really is `main` and that you don't widen this to `repo:ORG/REPO:*` (which would let *any* branch/PR/tag assume the role). |
| **`permission-policy.json` example** | 🔴 The bundled example is **overly broad for production use** — it includes `iam:*`, `lambda:*`, `ssm:*`, `sts:AssumeRole` on `"Resource": "*"`. `iam:*` in particular is a privilege-escalation risk: a compromised workflow could create/attach new roles and policies, or escalate its own permissions. |
| **Least privilege** | 🔴 As shipped, the policy is meant as a *template*, not a safe default. Anyone using it as-is grants their CI far more power than most deployments need. |
| **Local temp files** | ✅ `trust-policy-temp.json` is git-ignored, so no leaked account IDs from local runs. |

###  Recommendation before sharing publicly / on LinkedIn

- Frame it as **"an OIDC bootstrap tool / educational template"**, not a drop-in production-ready security tool.
- Call out explicitly that `permission-policy.json` **must be scoped down** per project (remove the `iam:*`, `lambda:*`, `ssm:*` wildcards and `Resource: "*"`).
- Recommend readers **pin the script to a specific git tag/commit SHA** instead of `master` when running `curl | bash` against their own AWS accounts.
- Mention that the trust policy's `sub` condition should match the **exact branch/environment** they intend to trust.

With those caveats stated, it's a great, legitimate showcase of **AWS OIDC + GitHub Actions automation** — just be transparent that the bundled policy is a customizable example, not a hardened default.

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
