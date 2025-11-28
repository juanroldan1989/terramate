# Enterprise Infrastructure Management

This project implements a structured enterprise infrastructure configuration following the hierarchy:

```
environments → regions → infrastructure layers → components
```

## Key Components

- **Terraform Modules**: Reusable infrastructure components sourced from the [infra-modules](https://github.com/juanroldan1989/infra-modules) repository
- **Terragrunt Framework**: Handles environment configuration and orchestrates infrastructure provisioning
- **Terramate**: Provides advanced stack management and CI/CD integration capabilities

## Documentation
- **[Infrastructure Setup & Usage](README.md#setup)** - Getting started with Terramate, Terragrunt, and Terraform
- **[Drift Detection Strategy](DRIFT.md)** - Comprehensive drift monitoring across environments and regions
- **[Disaster Recovery Documentation](enterprise/DR.md)** - Multi-region failover capabilities and procedures

## Infrastructure
- **[Enterprise Environments](enterprise/)** - Production-ready infrastructure across dev/qa/prod environments
  - **[Development](enterprise/dev/)** - US-based development infrastructure (us-east-1, us-west-1)
  - **[QA](enterprise/qa/)** - EU testing environment (eu-west-1)
  - **[Production](enterprise/prod/)** - EU production infrastructure (eu-central-1)

## Automation & CI/CD
- **[GitHub Actions Workflows](.github/workflows/)** - Automated infrastructure management
  - **[Infrastructure Preview](.github/workflows/infra-preview.yaml)** - PR-based change validation
  - **[Infrastructure Provisioning](.github/workflows/provision-infra.yaml)** - Automated deployment to production
  - **[Drift Detection Workflows](.github/workflows/drift-detection/)** - Multi-environment drift monitoring

## Configuration
- **[Terramate Configuration](terramate.tm.hcl)** - Stack management and orchestration
- **[Root Configuration](root.hcl)** - Shared Terragrunt configuration and AWS provider setup
- **[Bootstrap Scripts](bootstrap/)** - Initial infrastructure setup utilities

## Provision infrastructure

### For `dev/us-east-1`

```ruby
# enterprise/dev/us-east-1

./infra-management.sh apply
```

### For `dev/us-west-1`

```ruby
# enterprise/dev/us-west-1

./infra-management.sh apply
```

### For `dev/global/failover`

```ruby
# enterprise/dev/global/failover

terragrunt run apply
```

## Delete infrastructure

### For `dev/us-east-1`

```ruby
# enterprise/dev/us-east-1

./infra-management.sh destroy
```

## Sync stacks on Terramate - Steps

1. Install CLIs: `terragrunt`, `terraform` and `terramate`
2. import existing Terragrunt modules (modules with a state backend configuration) as Terramate stacks:

```ruby
terramate create --all-terragrunt
```

This command detects your existing Terragrunt modules, creates a stack configuration in each of them

and automatically sets up the **order of execution** using the **before** and **after** attributes based on detected Terragrunt dependencies.

3. List all Stacks:

```ruby
terramate list
```

4. Set required ENV variables for Terragrunt:

```ruby
export AWS_ACCOUNT_ID=xxxxxx
```

5. Initialize Terraform with Terragrunt:

```ruby
terramate run -- terragrunt init
```

6. Create a Terraform Plan with Terragrunt in Parallel:

```ruby
terramate run --parallel 5 -- terragrunt plan -out plan.tfplan
```

7. Apply a Terraform Plan with Terragrunt in Changed Stacks:

```ruby
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

```ruby
export GITHUB_TOKEN=your_personal_access_token_here
```

9. Sync Terragrunt modules provisioned as **stacks** in Terramate:

```ruby
terramate run \
  --continue-on-error \
  --cloud-sync-drift-status \
  --terraform-plan-file=drift.tfplan \
  --terragrunt \
  -- terragrunt plan -out drift.tfplan -detailed-exitcode -lock=false
```

![alt text](<screenshots/stacks.png>)

- The easiest way to sync your stacks is to run a drift detection workflow in all stacks and sync the result to Terramate Cloud.

- The command above runs a `terragrunt plan` in all your stacks and sends the result to Terramate Cloud.

- This works because Terramate CLI extracts data such as metadata, resources, Git metadata, and more from the created plans and the environment in which it's running, sanitizes it locally and syncs the result to Terramate Cloud. **This makes Terramate extremely secure** since no sensitive information, such as credentials or certificates, will ever be synced to Terramate Cloud.

## Contributing

Contributions are welcomed to this open source project!

### How to Contribute

1. **Fork the repository** and create a feature branch
2. **Make your changes** following the existing code style and patterns
3. **Test thoroughly** - Ensure your changes work across different environments
4. **Submit a pull request** with a clear description of your changes
5. **Participate in code review** - Address feedback and collaborate on improvements

### Getting Help

- 📖 Check the [documentation](README.md#sync-stacks-on-terramate---steps) for setup and usage guides
- 🐛 [Open an issue](https://github.com/juanroldan1989/terramate/issues) for bug reports or feature requests
- 💬 Start a [discussion](https://github.com/juanroldan1989/terramate/discussions) for questions or ideas

## License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.

The MIT License is a permissive license that allows you to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software, provided that the above copyright notice and this permission notice appear in all copies.
