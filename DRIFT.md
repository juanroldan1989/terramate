# Infrastructure Drift Detection

## Overview

Infrastructure drift occurs when the actual state of deployed resources diverges from the intended configuration defined in your Infrastructure as Code (IaC). This can happen due to manual changes, external modifications, or configuration updates outside of your deployment pipeline. Detecting and managing drift is critical for maintaining infrastructure reliability, security, and compliance.

This repository implements a comprehensive drift detection strategy using Terramate, Terragrunt, and GitHub Actions to monitor infrastructure across multiple environments and regions.

## GitHub Actions Workflows

### Infrastructure Management Workflows

- **`infra-preview.yaml`** - Preview infrastructure changes on pull requests
  - **Trigger**: Pull request events
  - **Purpose**: Validate and preview changes before merge
  - **Scope**: Changed stacks only (`--changed` flag)
  - **Features**: Format checking, validation, and plan generation with Terramate Cloud sync

- **`provision-infra.yaml`** - Deploy infrastructure changes to production
  - **Trigger**: Push to main branch
  - **Purpose**: Automated deployment of approved changes
  - **Scope**: Changed stacks in production environment
  - **Security**: OIDC authentication with AWS

### Example A

1. Infrastructure provisioned.
2. Pull Request is created: ECS Service adjusted to have **3** tasks associated.
3. Terramate shows "Preview" of changes:

![alt text](<screenshots/github-pull-request-preview.png>)

3. Terramate Cloud also shows "Preview" of changes:

![alt text](<screenshots/terramate-pull-request-preview.png>)

![alt text](<screenshots/terramate-pull-request-preview-ascii.png>)

4. PR is reviewed, approved and merged:

![alt text](<screenshots/pull-request-merged.png>)

5. Infrastructure changes are automatically provisioned via Github Action workflow:

![alt text](<screenshots/github-provision-infra.png>)

### Example B

1. Infrastructure provisioned.
2. ECS Service is adjusted via ClickOps.
3. "Drift Detection" workflow is triggered (on-demand / every 1 hour).
4. Terramate Cloud shows ECS Service as "drifted" resource:

![alt text](<screenshots/terramate-detects-drifted-resource.png>)

## Drift Detection Workflows

This infrastructure implements a **hybrid environment-based approach with region matrices** for comprehensive drift detection across multiple environments and regions:

### Environment-Specific Workflows

1. **`drift-detection/prod.yaml`** - Critical production infrastructure
   - **Schedule**: Every 6 hours (`0 */6 * * *`)
   - **Regions**: eu-central-1, eu-west-1 (matrix strategy)
   - **Parallelism**: 8 concurrent executions
   - **Tags**: `Environment:prod,Region:${{ matrix.region }}`
   - **Priority**: Highest - production stability monitoring

2. **`drift-detection/qa.yaml`** - QA environment validation
   - **Schedule**: Twice daily (`0 2,14 * * *`) - 2 AM and 2 PM UTC
   - **Regions**: eu-south-1, eu-west-2 (matrix strategy)
   - **Parallelism**: 8 concurrent executions
   - **Tags**: `Environment:qa,Region:${{ matrix.region }}`
   - **Purpose**: Pre-production validation and testing stability

3. **`drift-detection/dev.yaml`** - Development environment monitoring
   - **Schedule**: Three times per week (`0 2 * * 1,3,5`) - Monday, Wednesday, Friday at 2 AM UTC
   - **Regions**: us-east-1, us-west-1 (matrix strategy)
   - **Parallelism**: 8 concurrent executions
   - **Tags**: `Environment:dev,Region:${{ matrix.region }}`
   - **Purpose**: Development environment stability monitoring

4. **`drift-detection/on-demand.yaml`** - Complete infrastructure audit
   - **Trigger**: Manual only (workflow_dispatch)
   - **Scope**: All environments and regions (no filtering)
   - **Parallelism**: 5 concurrent executions
   - **Purpose**: Comprehensive drift analysis and troubleshooting

## Regional Distribution Strategy

The current implementation demonstrates a sophisticated multi-region strategy:

- **Production (EU Focus)**: eu-central-1, eu-west-1 - European production workloads
- **QA (EU Secondary)**: eu-south-1, eu-west-2 - European testing and validation regions
- **Development (US Focus)**: us-east-1, us-west-1 - US-based development and experimentation

This distribution provides:
- **Geographic isolation** between environments (EU production vs US development)
- **Regional disaster recovery** within each environment
- **Compliance alignment** with data residency requirements

## Benefits of the Hybrid Approach

### **Isolation & Risk Management**
- **Production isolation**: Critical production issues in EU regions are not masked by US development environment activity
- **Blast radius control**: Failed drift detection in one environment/region doesn't impact others
- **Environment SLAs**: Production (6h frequency) vs QA (12h) vs Development (48-72h)

### **Optimized Resource Usage**
- **Parallelism based on environment**: `prod` (`12` - higher for faster detection), `qa` (`8`) and `dev` (`4` - lower to conserve resources).
- **Frequency optimization**: Production monitored most frequently (every 6 hours), development least frequent (3x/week)
- **Regional efficiency**: Matrix strategy runs regions in parallel rather than sequentially

### **Operational Excellence**
- **Environment-specific alerting**: Production alerts can be routed to EU on-call teams, development to US development teams
- **Compliance**: Separate audit trails for EU production vs US development environments
- **Maintenance windows**: Regional matrix allows for region-specific maintenance schedules

### **Scalability & Flexibility**
- **Tag-based filtering**: Leverages `Environment:$env,Region:$region` tagging for precise targeting
- **Easy expansion**: Adding new regions requires only updating the matrix configuration
- **Cross-environment learning**: Development drift patterns can inform production monitoring strategies

This multi-regional, environment-based approach provides comprehensive infrastructure monitoring while respecting operational, compliance, and geographic requirements.
