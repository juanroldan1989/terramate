# Terramate

This project is used to try Terramate to provision infrastructure.

## Setup

- Environments structure follows [sisyphus](https://github.com/juanroldan1989/sisyphus) repository.

- Modules used on this project come from [infra-modules](https://github.com/juanroldan1989/infra-modules) repository.

- Terragrunt framework is used to configure environment and provision infrastructure through modules.

## Provision infra

### For `dev/us-east-1`

```bash
# enterprise/dev/us-east-1

./infra-management.sh apply
```

### For `dev/us-west-1`

```bash
# enterprise/dev/us-west-1

./infra-management.sh apply
```

### For `dev/global/failover`

```bash
# enterprise/dev/global/failover

terragrunt run apply
```

## Sync stack on Terramate - Steps

1. Install CLIs: `terragrunt`, `terraform` and `terramate`
2. import existing Terragrunt modules (modules with a state backend configuration) as Terramate stacks:

```bash
terramate create --all-terragrunt
```
This command detects your existing Terragrunt modules, creates a stack configuration in each and automatically sets up the **order of execution** using the **before** and **after** attributes based on detected Terragrunt dependencies.

3. List all Stacks:

```bash
terramate list
```

4. Set required ENV variables for Terragrunt:

```bash
export AWS_ACCOUNT_ID=xxxxxx
```

5. Initialize Terraform with Terragrunt:

```bash
terramate run -- terragrunt init
```

6. Create a Terraform Plan with Terragrunt in Parallel:

```bash
terramate run --parallel 5 -- terragrunt plan -out plan.tfplan
```

7. Apply a Terraform Plan with Terragrunt in Changed Stacks:

```bash
terramate run --changed -- terragrunt apply -auto-approve plan.tfplan
```

8. Create a GitHub Personal Access Token for Terramate Cloud sync:

- Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Click "Generate new token (classic)"
- Give it a descriptive name like "Terramate Cloud Sync"
- Set an appropriate expiration date
- Select the following scopes:
  - **`repo`** - Full control of private repositories (includes public repos)
  - **`read:org`** - Read org and team membership (if using organization repos)
- Export the token as an environment variable:

```bash
export GITHUB_TOKEN=your_personal_access_token_here
```

9. Sync Terragrunt modules provisioned as **stacks** in Terramate:

```bash
terramate run \
  --continue-on-error \
  --cloud-sync-drift-status \
  --terraform-plan-file=drift.tfplan \
  --terragrunt \
  -- terragrunt plan -out drift.tfplan -detailed-exitcode -lock=false
```

- The easiest way to sync your stacks is to run a drift detection workflow in all stacks and sync the result to Terramate Cloud.

- The command above runs a `terragrunt plan` in all your stacks and sends the result to Terramate Cloud.

- This works because Terramate CLI extracts data such as metadata, resources, Git metadata, and more from the created plans and the environment in which it's running, sanitizes it locally and syncs the result to Terramate Cloud. **This makes Terramate extremely secure** since no sensitive information, such as credentials or certificates, will ever be synced to Terramate Cloud.

## Docs

https://terramate.io/docs/cli/on-boarding/terragrunt
