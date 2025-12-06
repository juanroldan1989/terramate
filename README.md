# Enterprise Infrastructure Management

Multi-region & multi-account enterprise infrastructure designed for scaling to hundreds of components. The architecture implements a three-tier infrastructure model (networking, compute, applications) with automated drift detection, CI/CD pipelines and cross-regional failover capabilities.

![alt text](<zdocs/screenshots/dev-environment.png>)

## Folder Structure

```ruby
enterprise/
├── dev/                        # Development Environment
│   ├── account.hcl               # AWS account configuration
│   ├── global/                   # Global/cross-region resources
│   │   ├── region.hcl              # Global region settings
│   │   └── failover/               # Cross-region failover configuration
│   │
│   ├── us-east-1/              # Primary US region
│   │   ├── region.hcl            # Region-specific settings
│   │   ├── 01-networking/        # VPC, subnets, security groups
│   │   ├── 02-compute/           # ECS clusters, EKS clusters
│   │   └── 03-applications/      # Application services
│   │
│   └── us-west-1/              # Secondary US region (DR)
│       ├── region.hcl            # Region-specific settings
│       ├── 01-networking/        # VPC, subnets, security groups
│       ├── 02-compute/           # ECS clusters, EKS clusters
│       └── 03-applications/      # Application services
│
├── qa/                         # QA/Testing Environment
│   ├── account.hcl               # AWS account configuration
│   └── eu-south-1/               # EU testing region
│       ├── region.hcl              # Region-specific settings
│       ├── 01-networking/          # VPC, subnets, security groups
│       ├── 02-compute/             # ECS clusters, EKS clusters
│       └── 03-applications/        # Application services
│   ...
│
├── prod/                       # Production Environment
│   ├── account.hcl               # AWS account configuration
│   └── eu-central-1/             # EU production region
│       ├── region.hcl              # Region-specific settings
│       ├── 01-networking/          # VPC, subnets, security groups
│       ├── 02-compute/             # ECS clusters, EKS clusters
│       └── 03-applications/        # Application services
│   ...
│
├── scripts/                    # Utility scripts
│   └── dr-test.sh                # Failover testing
├── DR.md                       # Failover switch documentation
└── README.md                   # Enterprise documentation
```

### Infrastructure Layers

- **01-networking/**: Foundation layer containing VPCs, subnets, security groups and network ACLs
- **02-compute/**: Compute resources including ECS clusters, EKS clusters and auto-scaling groups
- **03-applications/**: Application-specific services and resources built on top of compute and networking

## Key Components

- **Terraform Modules**: Reusable infrastructure components sourced from the [infra-modules](https://github.com/juanroldan1989/infra-modules) repository
- **Terragrunt Framework**: Handles environment configuration and orchestrates infrastructure provisioning
- **Terramate**: Provides advanced stack management and CI/CD integration capabilities

## Infrastructure
- **[Enterprise Environments](enterprise/)** - Production-ready infrastructure across dev/qa/prod environments
  - **[Development](enterprise/dev/)** - US-based development infrastructure (us-east-1, us-west-1)
  - **[QA](enterprise/qa/)** - EU testing environment (eu-west-1)
  - **[Production](enterprise/prod/)** - EU production infrastructure (eu-central-1)
- **[Architecture Overview](zdocs/ARCH.md)** - Multi-region, multi-account enterprise infrastructure designed for scaling to hundreds of components.

## Automation & CI/CD

**[GitHub Actions Workflows](.github/workflows/)** - Automated infrastructure management

- **[Infrastructure Changes Preview](.github/workflows/infra-changes-preview.yaml)** - PR-based change validation
- **[Infrastructure Costs Preview](.github/workflows/infra-costs-preview.yaml)** - PR-based infrastructure costs estimation
- **[Infrastructure Security Preview](.github/workflows/infra-security-preview.yaml)** - PR-based infrastructure Tfsec security best practices validation
- **[Infrastructure Provisioning](.github/workflows/provision-infra.yaml)** - Automated deployment to production
- **[Drift Detection Workflows](.github/workflows/)** - Multi-environment drift monitoring support for on-demand and scheduled runs (`drift-detection-<env>.yaml` files).

## Provision infrastructure

![alt text](<zdocs/screenshots/dev-provisioning.gif>)

```ts
...

11:02:22.948 STDOUT [03-applications/service-a] terraform: Outputs:
11:02:22.948 STDOUT [03-applications/service-a] terraform:
11:02:22.948 STDOUT [03-applications/service-a] terraform: alb_zone_id = "Z35SXDOTRQ7X7K"
11:02:22.948 STDOUT [03-applications/service-a] terraform: ecs_task_sg_id = "sg-0e827d8bbe8b26698"
11:02:22.948 STDOUT [03-applications/service-a] terraform: log_group_name = "/ecs/log-group/dev/app-a"
11:02:22.948 STDOUT [03-applications/service-a] terraform: service_name = "service-a"
11:02:22.948 STDOUT [03-applications/service-a] terraform: service_url = "dev-us-east-1-app-a-alb-48296827.us-east-1.elb.amazonaws.com"

❯❯ Run Summary  3 units  5m
   ────────────────────────────
   Succeeded    3
```

```ts
➜  terramate git:(main) ✗ curl dev-us-east-1-app-a-alb-48296827.us-east-1.elb.amazonaws.com
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```


### Development Environment - Primary Region

Deploy infrastructure to the primary development region:

```bash
cd enterprise/dev/us-east-1
./infra-management.sh apply
```

### Development Environment - Secondary Region

Deploy infrastructure to the secondary development region for disaster recovery:

```bash
cd enterprise/dev/us-west-1
./infra-management.sh apply
```

### Development Environment - Global Failover Configuration

Configure cross-region disaster recovery resources:

```bash
cd enterprise/dev/global/failover
terragrunt run-all apply
```

**Note**: Ensure proper AWS credentials and permissions are configured before executing deployment commands. Review the generated Terraform plans before applying changes to production environments.

## Destroy Infrastructure

![alt text](<zdocs/screenshots/dev-destroy.gif>)

### Development Environment - Primary Region

To safely remove all infrastructure resources from the primary development region:

```bash
cd enterprise/dev/us-east-1
./infra-management.sh destroy
```

**Warning**: This operation will permanently delete all infrastructure resources in the specified environment. Ensure you have:

- Backed up any critical data
- Confirmed this is the intended environment
- Reviewed the destruction plan before proceeding

## State Management

This infrastructure uses AWS-managed state backend for secure and collaborative development. The bootstrap script provisions the following components with enterprise-grade security configurations:

- **S3 State Bucket**: Encrypted storage for Terraform state files with versioning enabled
- **S3 Access Logging Bucket**: Centralized audit trail for state bucket operations
- **DynamoDB Lock Table**: Distributed locking mechanism to prevent concurrent state modifications

Execute the bootstrap script to initialize the backend infrastructure:

```bash
./bootstrap/setup-backend.sh
```

**Prerequisites**: Ensure AWS credentials are configured with appropriate IAM permissions for S3 and DynamoDB resource creation.

## Sync stacks on Terramate - Steps

1. **Prerequisites**: Install required command-line tools:
  - `terragrunt` - Infrastructure orchestration and configuration management
  - `terraform` - Infrastructure as Code provisioning engine
  - `terramate` - Stack management and CI/CD integration platform

2. **Import Existing Infrastructure**: Convert existing Terragrunt modules with configured state backends into Terramate stacks:

```ruby
terramate create --all-terragrunt
```

This command detects your existing Terragrunt modules, creates a stack configuration in each of them and automatically sets up the **order of execution** using the **before** and **after** attributes based on detected Terragrunt dependencies.

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

![alt text](<zdocs/screenshots/stacks.png>)

- The easiest way to sync your stacks is to run a drift detection workflow in all stacks and sync the result to Terramate Cloud.

- The command above runs a `terragrunt plan` in all your stacks and sends the result to Terramate Cloud.

- This works because Terramate CLI extracts data such as metadata, resources, Git metadata and more from the created plans and the environment in which it's running, sanitizes it locally and syncs the result to Terramate Cloud. **This makes Terramate extremely secure** since no sensitive information, such as credentials or certificates, will ever be synced to Terramate Cloud.

## Documentation
- **[Infrastructure Setup & Usage](README.md#setup)** - Getting started with Terramate, Terragrunt and Terraform
- **[Drift Detection Strategy](zdocs/DRIFT.md)** - Comprehensive drift monitoring across environments and regions
- **[Failover Support Documentation](enterprise/DR.md)** - Multi-region failover capabilities and procedures

## Configuration
- **[Terramate Configuration](terramate.tm.hcl)** - Stack management and orchestration
- **[Root Configuration](root.hcl)** - Shared Terragrunt configuration and AWS provider setup
- **[Bootstrap Scripts](bootstrap/)** - Initial infrastructure setup utilities

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

The MIT License is a permissive license that allows you to use, copy, modify, merge, publish, distribute, sublicense and/or sell copies of this software, provided that the above copyright notice and this permission notice appear in all copies.
