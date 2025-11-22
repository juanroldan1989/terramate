# Terramate

This project is used to try Terramate to provision infrastructure.

## Setup

- Environments structure follows [sisyphus](https://github.com/juanroldan1989/sisyphus) repository.

- Modules used on this project come from [infra-modules](https://github.com/juanroldan1989/infra-modules) repository.

- Terragrunt framework is used to configure environment and provision infrastructure through modules.

## Steps

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

4. Initialize Terraform with Terragrunt:

```bash
terramate run -- terragrunt init
```

5. Create a Terraform Plan with Terragrunt in Parallel:

```bash
terramate run --parallel 5 -- terragrunt plan -out plan.tfplan
```

6. Apply a Terraform Plan with Terragrunt in Changed Stacks:

```bash
terramate run --changed -- terragrunt apply -auto-approve plan.tfplan
```

## Docs

https://terramate.io/docs/cli/on-boarding/terragrunt
