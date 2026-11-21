# Roadmap

Turn the existing two-region AWS development implementation into a reproducible
infrastructure delivery and recovery case study. Demonstrate component boundaries,
reviewable changes, cost visibility, drift detection, access controls and measured
recovery, with evidence that engineers and recruiters can inspect.

Use Floci to exercise local provisioning, configuration adjustments, drift detection,
bounded reconciliation loops and final verification through the actual Terramate,
Terragrunt and Terraform tools. Reuse the supported infrastructure components across
local and AWS paths, while recording emulator compatibility and AWS validation
separately.

Milestones are ordered by increasing implementation complexity, from documentation
and small configuration fixes to local integration tests, AWS lifecycle tests, recovery and account
isolation. This is an implementation order, not a severity ranking: address exposed
credentials or unsafe access before running a deployment, even where their complete
replacement appears in a later milestone. Dependencies are called out explicitly.

All checklist items describe pending work. Existing recordings and walkthroughs
are historical evidence; they do not establish that the current revision passes
the proposed acceptance checks. Mark an item complete only with its implementation
and relevant verification recorded.

## Current baseline

The repository review on 2026-11-19 found the following tracked source, excluding
local Terraform and Terragrunt caches:

| Area | Observed state |
| --- | --- |
| Terramate stacks | Eight, all under `enterprise/dev/` |
| Configured regions | `us-east-1`, `us-west-1`, plus global failover configuration |
| Terragrunt components | Nine nonempty configurations; Service B has no Terramate stack definition |
| QA and production | Empty account, region and component configuration scaffolding |
| Account isolation | Intended structure; no complete demonstrated multi-account deployment path |
| Drift monitoring | On-demand workflows exist; schedules are commented out |
| Regional drift filter | The current development filter selected zero stacks locally |
| Other cloud providers | No demonstrated GCP or Azure implementation |
| Local checks | Terramate formatting and Bash syntax checks passed |
| AWS execution | Not rerun during the review; historical deployment and failover evidence exists |

Recheck this baseline when work starts. Keep configured, historically demonstrated,
locally verified, AWS verified and planned capabilities distinct.

The Floci path added to this roadmap on 2026-11-21 is planned work. No local
provisioning, runtime, drift or reconciliation result is established by this document.

## 1. Correct documentation and portfolio claims

Complexity: low. Can start immediately.

- [ ] Add a capability matrix to the main README using the status distinctions
  above. Include tested revision, versions, date and evidence for verified paths.
- [ ] Label QA, production, EKS and additional components as scaffolding wherever
  their configuration is incomplete. Explain what a contributor can actually run.
- [ ] Align the README and architecture documentation around networking, compute,
  applications and monitoring. Describe state boundaries per component rather
  than implying one state file per entire layer.
- [ ] Correct outdated workflow names, region references, configuration examples
  and broken documentation links.
- [ ] Distinguish AWS resource tags from Terramate stack tags.
- [ ] Label recovery times in existing documentation as historical observations
  with their available context. Remove unsupported RTO, RPO, database replication,
  compliance and unlimited-scale claims.
- [ ] In `automatalife`, revise the project card, case study and metadata to describe
  the implemented AWS development scope. Remove claims of deployed QA/production,
  proven account isolation, active scheduled scans and zero-change cloud migration.
- [ ] Use a descriptive case-study title such as **AWS Infrastructure Delivery and
  Recovery** so authorship of this implementation is clear.
- [ ] Replace `N` regions, infinite cloud providers and `3+` deployed environments
  with verified scope. Replace the long Nginx HTML output with a short result.

Acceptance: a reader can identify what works, what was demonstrated historically
and what remains planned without inferring capabilities from empty folders.

Related: [README](../README.md), [architecture](ARCH.md), [drift](DRIFT.md),
[recovery](../enterprise/DR.md). Website changes belong in the `automatalife` repo.

## 2. Complete stack registration and selection

Complexity: low. Depends on the supported scope established in milestone 1.

- [ ] Register development Service B as a Terramate stack with an ID and its
  networking/cluster execution dependencies.
- [ ] Give supported stacks meaningful descriptions and a documented tagging
  scheme using valid tag names, for example `env-dev` and `region-us-east-1`.
- [ ] Update regional selection expressions to use the intended intersection,
  for example `--tags env-dev:region-us-east-1`, rather than key/value assumptions.
- [ ] Define where global failover stacks belong in drift scans and deployment
  selection; ensure they are not omitted by regional filters.
- [ ] Add a lightweight check for expected stack membership, unique IDs, valid
  dependency paths and supported Terragrunt components missing stack metadata.
- [ ] Keep incomplete scaffolding out of executable selections. Document how a
  new component becomes supported.

Acceptance: each supported environment/region filter returns its documented stack
set, and an unexpectedly empty selection fails validation instead of passing silently.

## 3. Repair workflow conditions and command consistency

Complexity: low to moderate. Depends on milestone 2.

- [ ] Replace reliance on implicit `steps.list.outputs.stdout` in preview,
  deployment, cost and security workflows. Publish an explicit stack count or
  `has_changes` output through `GITHUB_OUTPUT` and consume it consistently.
- [ ] Distinguish a legitimate no-change run from a failed stack-discovery command.
- [ ] Make formatting checks read-only and fail on unexpected generated changes.
  Remove `git add .` and the pattern that reports a dirty checkout but continues.
- [ ] Check Terragrunt formatting with the appropriate HCL command for the pinned
  version; separate that from Terraform formatting inside modules.
- [ ] Align noninteractive flags and command syntax across workflows and scripts.
- [ ] Remove unsupported inputs passed to the infrastructure-tools composite
  action, or define and use them if needed.
- [ ] Consolidate repeated setup and selection behavior where it reduces drift
  between workflows without hiding their execution scope.
- [ ] Verify conditions with a changed component, a documentation-only change and
  an intentional discovery/configuration failure.

Acceptance: selected changes reach validation, planning and deployment steps;
no-change runs are explicit; invalid input cannot produce a misleading green run.

## 4. Pin releases and fix module/application contracts

Complexity: moderate. Coordinate module changes with `infra-modules`.

- [ ] Pin remote module sources to immutable commits and document their release
  provenance and update process. Avoid consuming an evolving default branch.
- [ ] Record a tested Terraform/Terragrunt/Terramate/AWS-provider compatibility set
  and align local setup with CI. Review lockfile handling for every supported stack.
- [ ] Use controlled application release identifiers, preferably image digests,
  and document how updates and rollback are proposed and verified.
- [ ] Fix the networking contract: Terragrunt supplies `vpc_cidr`, while the reviewed
  local module expects `cidr`. Validate subnet CIDRs against the chosen network.
- [ ] Fix the ECS capacity contract: use a valid launch type or an explicit Fargate
  Spot capacity-provider strategy. Add validation for supported choices.
- [ ] Make image, port, container name and health endpoint explicit. The current
  Flask services expose `/health`; verify the health contract of the actual image.
- [ ] Give primary and secondary Service A the same application release and
  behavior, with intentional region-specific settings.
- [ ] Restrict dependency mocks to appropriate validation commands. Ensure actual
  deployment cannot silently use placeholder network or cluster outputs.
- [ ] Add focused module/input checks for the contract failures above. Verify the
  chosen remote revisions; a sibling checkout alone does not establish their content.

Acceptance: a recorded release resolves to known module/image inputs, and interface
errors fail before cloud deployment.

## 5. Add an isolated Floci execution environment

Complexity: moderate. Depends on milestones 2 and 4; cloud authentication and AWS
backend work can proceed separately.

- [ ] Add a version-pinned Docker Compose setup for Floci with readiness checks,
  documented Docker prerequisites, persistence settings and start/stop/reset commands.
- [ ] Create an explicit local environment with distinct Terramate stack IDs, tags,
  resource names and state paths. Verify local selection cannot include AWS stacks.
- [ ] Use dummy credentials and explicit local endpoint configuration for every
  AWS service used by the scenario. Keep provider overrides at the environment
  composition/generation layer rather than inside reusable modules.
- [ ] Configure state independently of provider endpoints. Start with a local
  backend; add emulated S3/locking later as a separate compatibility exercise.
  Never reuse an AWS backend or existing AWS state for local execution.
- [ ] Add preflight checks that reject missing or nonlocal resource/backend endpoints
  and inherited real credentials for the local path. Fail without falling back to AWS.
- [ ] Pin and record Floci, Terraform, Terragrunt, Terramate, provider, module and
  image versions. Check the exact API operations used by those module revisions;
  a service appearing in Floci's support list does not establish scenario compatibility.
- [ ] Establish a small disposable resource smoke test through Terramate and
  Terragrunt to verify endpoint targeting, state isolation and cleanup before
  attempting the complete application scenario.
- [ ] Configure Docker-backed execution for workload tests. Document Docker socket,
  image architecture, networking, listener-port and hostname requirements. Keep
  API-only/mock results separate from actual container execution evidence.
- [ ] Document module/image downloads and other network prerequisites. Local
  infrastructure provisioning does not imply an entirely offline workflow.
- [ ] Publish a local quickstart and compatibility matrix, including unsupported
  operations, environment-specific settings and checks reserved for AWS.

Acceptance: a fresh checkout can start the pinned emulator and create, inspect and
remove the smoke-test resource through the real toolchain using isolated local state.
Missing emulator configuration fails locally instead of targeting AWS.

References: [Floci Terraform setup](https://github.com/floci-io/floci/blob/main/docs/getting-started/terraform.md),
[ECS runtime](https://floci.io/floci/services/ecs/),
[Terramate orchestration](https://terramate.io/docs/cli/orchestration/run-commands-in-stacks).
Recheck support against the pinned versions during implementation.

## 6. Make cost and security reporting dependable

Complexity: moderate. Depends on milestones 3 and 4.

- [ ] Discover plan files in the actual Terragrunt execution directories and
  generate reports for every selected stack.
- [ ] Write reports to a deliberate shared output directory with unique stack
  identifiers. Aggregate those files and upload the same artifacts.
- [ ] Exclude combined reports from input globs; the existing security aggregation
  can include its own output file.
- [ ] Treat missing reports, failed scans and malformed JSON as errors. Remove
  parsing fallbacks that turn failures into zero findings.
- [ ] Define the security threshold and exception process. Verify the scanner
  invocation fails the required check when the threshold is exceeded.
- [ ] Make Infracost credential availability and optional/required behavior explicit.
  Document coverage and assumptions; estimated infrastructure cost is not a bill.
- [ ] Generate a real base-versus-proposed cost comparison before advertising a
  cost diff. Include usage assumptions and unestimated resources.
- [ ] Verify PR comments update the intended report and include all selected stacks.
- [ ] Protect state and plan artifacts from unnecessary access or disclosure;
  define artifact retention and keep sensitive plan content out of public comments.
- [ ] Exercise multiple-stack reports, no-change runs, a deliberate critical
  finding, scanner failure, missing credentials and invalid report input.
- [ ] Exercise report collection with plans from the Floci path where supported.
  Label cost estimates as projections for the modeled AWS configuration, not local
  runtime costs or evidence of an AWS deployment. Record any external API requirements.

Acceptance: a missing or broken check cannot look like a clean result, and the PR
contains an attributable cost/security report for every selected component.

Related: [cost documentation](COST.md), [workflows](../.github/workflows/).

## 7. Establish safe access and deployment boundaries

Complexity: moderate to high. Required before AWS lifecycle exercises.

- [ ] Remove the committed Grafana password. Rotate it if it has been deployed,
  and obtain or generate credentials through a documented secret-management path.
  Marking a Terraform variable sensitive does not remove it from state.
- [ ] Replace unrestricted Grafana ingress with an intentional access boundary.
  Add TLS to supported public application/monitoring endpoints and verify routing.
- [ ] Separate preview/drift permissions from deployment permissions. Constrain
  OIDC trust to the intended repository and branch/environment subjects.
- [ ] Replace manual IAM instructions with reviewed, reproducible role/policy
  provisioning. Reconcile the documented permissions with actual operations.
- [ ] Add GitHub deployment environments and required checks where appropriate.
  Inspect and record repository rules separately from workflow configuration.
- [ ] Serialize deployments that can touch the same stacks/state. Define how
  preview cancellation and already-running applies are handled.
- [ ] Verify account/region identity before changes and fail on an unexpected
  account instead of falling back to a placeholder ID.
- [ ] Separate application task and execution-role responsibilities and make
  required roles an explicit provisioned dependency.
- [ ] Pin third-party Actions to reviewed revisions and establish an update path.
- [ ] Demonstrate denied access for an unintended deployment context and safe
  behavior when two deployment requests overlap.

Acceptance: intended workflows have the permissions they need, unintended contexts
are denied, and concurrent requests do not create overlapping infrastructure changes.

Related: [IAM setup](IAM.md), [AWS authentication action](../.github/actions/setup-aws/action.yaml).

## 8. Make state bootstrap and cleanup reproducible

Complexity: moderate to high. Depends on milestones 4 and 7.

- [ ] Parameterize backend setup by account, region and environment. The current
  bootstrap targets `us-west-1`, while component backends also require `us-east-1`.
- [ ] Define ownership and lifecycle of backend resources separately from workloads.
  Make repeated setup safe and verify existing resources rather than assuming success.
- [ ] Verify encryption, versioning, public-access blocks, log-delivery permissions
  and actual log delivery. Enforce the claimed transport-security policy.
- [ ] Choose and test a state-locking strategy compatible with the selected tool
  versions; document any migration before changing backend configuration.
- [ ] Verify state isolation per component and locking during concurrent operations.
- [ ] Exercise recovery of a previous state version in a disposable fixture and
  explain its limits: restoring state does not restore application data/resources.
- [ ] Replace hardcoded teardown lists with a verified dependency-aware procedure,
  including global failover resources before their regional dependencies.
- [ ] Preserve backend/audit resources deliberately and identify them in cleanup
  reports so intentional retention is distinguishable from leaked workloads.
- [ ] If adding a Floci-backed S3/locking profile, provision its backend separately,
  configure backend service endpoints explicitly and test persistence across emulator
  restarts. Keep emulator results separate from AWS locking, audit and recovery evidence.

Acceptance: a fresh account/region can initialize every required backend; rerunning
setup is safe; locking, state recovery and workload cleanup have recorded evidence.

Related: [bootstrap script](../bootstrap/setup-backend.sh), [root configuration](../root.hcl).

## 9. Automate local provisioning, drift and reconciliation loops

Complexity: high. Depends on milestones 2–5. Use milestone 6 for report integration;
start with local state while AWS-specific work in milestones 7 and 8 remains pending.

- [ ] Build a single-region local scenario from the same supported networking,
  ECS cluster and application modules used by AWS. Begin with Service A; add
  Service B and monitoring only after their emulator compatibility is established.
- [ ] Reuse a released workload from `applications` with an explicit health endpoint
  and release identity. Keep local differences in environment configuration.
- [ ] Provision through Terramate in dependency order with real outputs. Assert
  expected resource configuration and relationships through the local AWS API.
- [ ] Verify running containers and reach release A through the provisioned
  application/load-balancer endpoint. Check target health separately; a successful
  HTTP response alone does not establish that health checks passed.
- [ ] Make an intended configuration adjustment, such as release A to B or replica
  count. Assert the selected stacks, inspect the plan, apply and verify the resulting
  application release, capacity and health. Exercise the supported rollback path.
- [ ] Confirm a second refreshed plan has no unexpected changes before injecting
  drift. Keep configuration changes and out-of-band changes as separate test cases.
- [ ] Inject controlled drift through the Floci AWS-compatible API/CLI, such as
  changing a Terraform-managed ECS desired count. Confirm that actual emulator state
  changed without editing configuration or Terraform state.
- [ ] Run a Terramate-orchestrated drift scan using a refreshed Terragrunt plan.
  Assert the affected stack and expected diff; distinguish no changes, drift and
  command errors using the tool's detailed exit-code behavior.
- [ ] Implement a bounded reconciliation driver for explicitly selected disposable
  local stacks: inspect drift → create a fresh correction plan → apply → wait for
  runtime convergence → replan. Terramate runs these commands; the driver or CI
  schedule supplies the loop rather than assuming a continuously running controller.
- [ ] Limit retries and total duration, preserve diagnostics and fail on unresolved
  drift. Verify another iteration after convergence makes no changes. Include a
  failed correction or unavailable emulator case so failure cannot appear successful.
- [ ] Perform final verification of application behavior, release, resource settings,
  target health, stack scope and a clean refreshed plan. Preserve the pre-cleanup
  result before destroying anything.
- [ ] Destroy in dependency order and verify removal through both the emulator API
  and Docker runtime. Check for remaining owned containers, resources and listeners;
  document deliberate backend or emulator persistence separately.
- [ ] Repeat from a clean fixture and run the lifecycle in CI with isolated emulator
  data, state and port allocation. Upload selected-stack lists, plans/results, runtime
  assertions and cleanup evidence without sensitive state or plan content.
- [ ] Add optional Terramate Cloud synchronization for deployment/drift results.
  Verify the integration with plans produced against Floci, use distinct local stack
  IDs and label the environment clearly. Keep core local tests independent of Cloud
  login, internet access and sync availability.
- [ ] Reuse component contracts and applicable assertions from `deploy-ecs-blueprint`
  while keeping this repository's tests focused on orchestration, change selection,
  drift and reconciliation. Avoid a second competing module implementation.

Acceptance: start Floci → provision → verify A → adjust → verify B → converge →
inject drift → detect → reconcile within bounds → verify behavior and clean plan →
destroy → verify API/runtime cleanup. A repeated run produces attributable results
for the pinned toolchain, including the expected failure cases.

Record API-only, Docker-runtime and AWS results separately. Floci success does not
establish AWS IAM/OIDC enforcement, VPC/security-group isolation, Fargate availability,
regional resilience or public Route 53 health-based failover. Document supported
local behavior and any accommodations without changing the intended AWS architecture
solely to satisfy the emulator.

References: [Floci ELB behavior](https://floci.io/floci/services/elb/),
[Route 53 limitations](https://floci.io/floci/services/route53/),
[Terramate Cloud synchronization](https://terramate.io/docs/get-started/terragrunt).

## 10. Automate a complete AWS single-region lifecycle

Complexity: high. Depends on milestones 2–9 for the supported scenario.

- [ ] Document prerequisites, credentials, DNS, IAM, backend setup and one supported
  development command path. Make manual steps explicit and check readiness.
- [ ] Reuse a recognizable workload from `applications` with health and release
  identity. Keep image publication and infrastructure delivery responsibilities clear.
- [ ] Provision networking, cluster, application and monitoring from a clean setup
  in dependency order. Do not plan dependents against placeholder bootstrap outputs.
- [ ] Verify the application response and release through the provisioned endpoint.
- [ ] Deploy release B, verify the served version, and exercise the documented
  rollback procedure.
- [ ] Confirm convergence with a subsequent plan showing no unexpected changes.
- [ ] Destroy the disposable workload and verify cloud-resource removal; an empty
  state file alone is insufficient cleanup evidence.
- [ ] Add bounded waits, failure diagnostics and cleanup handling to the harness.
- [ ] Record revision, versions, account/region, durations, costs/assumptions and
  results. Keep fast checks separate from tests that require real AWS.
- [ ] Reuse the applicable local lifecycle assertions from milestone 9 with AWS
  endpoint discovery and credentials. Record AWS-specific differences and pending
  checks explicitly; local success must not automatically mark AWS validation passed.

Acceptance: provision → verify A → update → verify B → rollback → converge → destroy
can be repeated from the documented starting point with inspectable results.

## 11. Prove AWS drift detection and change impact

Complexity: high. Depends on milestones 2, 3, 9 and 10.

- [ ] Run the corrected drift selections against supported stacks and sync results
  to Terramate Cloud. Confirm global resources are included as intended.
- [ ] Inject a controlled manual change, detect it, identify the affected stack and
  record detection time. Reconcile through the normal reviewed deployment path.
- [ ] Define notification routing, scan failure handling and the distinction between
  detected drift and a failed inspection.
- [ ] Enable schedules only for verified deployment scopes, with a documented
  frequency and cost rationale. Update documentation to match active triggers.
- [ ] Test selection for a component edit, shared root/account/region configuration
  changes, module-version updates and changes affecting dependent stacks.
- [ ] Verify both execution order and selection: ordering metadata alone does not
  establish that every affected dependent stack is included.
- [ ] Document the Git comparison base and behavior for multi-commit pushes, merges
  and retries. Ensure an earlier failed deployment can be retried deliberately.
- [ ] Reuse the local drift assertions against a disposable AWS scenario. Keep
  unattended reconciliation limited to the local fixture until an explicit AWS
  reconciliation policy and authorization boundary are implemented and verified.

Acceptance: a known drift event is detected and reconciled, and a small change-impact
matrix demonstrates which stacks are selected and why.

## 12. Prove two-region failover and failback

Complexity: high. Depends on milestones 4, 8 and 10.

- [ ] Deploy the same application release and compatible health configuration in
  both regions. Include region and release identity in an inspectable response.
- [ ] Update the DR script to discover or accept the real service name, capture
  original desired capacity and verify both regional endpoints before injection.
- [ ] Add bounded requests/waits, nonzero failure exits and restoration on error or
  interruption. Do not hardcode restoration to one task.
- [ ] Inject primary failure and assert that the shared endpoint serves the expected
  application from the secondary region, rather than accepting any HTTP success.
- [ ] Record injection, observed interruption, secondary response, primary recovery
  and failback. Explain DNS/cache effects and the measurement method.
- [ ] Verify restoration to original capacity and a clean subsequent infrastructure
  plan. Test failure of the exercise itself, including timeout and cleanup paths.
- [ ] Publish measured results as stateless application traffic recovery. Keep
  database replication, backup restore and data-loss claims outside that result
  until separately implemented and verified.
- [ ] Explain the single-NAT-per-region cost/availability tradeoff and which failure
  modes the demonstration covers. Account for standby infrastructure costs.

Acceptance: repeatable drills prove correct application behavior during failover,
safe restoration and measured results tied to a specific release.

Related: [recovery walkthrough](../enterprise/DR.md), [DR script](../enterprise/scripts/dr-test.sh).

## 13. Demonstrate real account isolation and promotion

Complexity: very high. Depends on a stable lifecycle and access/state boundaries.

- [ ] Implement a second AWS account with explicit account configuration, OIDC
  roles, backend ownership and deployment environment boundaries.
- [ ] Promote the same immutable module/image release between supported environments
  using environment configuration. Define review and rollback requirements.
- [ ] Demonstrate that preview/deployment in one account cannot read or modify
  another account's state or workloads except through explicitly authorized paths.
- [ ] Verify account targeting, failed-role assumptions and denied-access behavior.
- [ ] Populate QA or production scaffolding only as its implementation is exercised.
  Publish an updated capability matrix with evidence for each supported path.

Acceptance: one release is deployed through two independently controlled account
boundaries, with positive and negative access evidence. Folder names alone do not
count as isolation or a production operating history.

## 14. Validate scale and consolidate the portfolio story

Complexity: very high for scale testing; documentation can evolve throughout.

- [ ] Explain the responsibilities and maintenance costs of Terraform, Terragrunt
  and Terramate, including when a simpler combination would be sufficient.
- [ ] Decide module ownership across this project, `infra-modules` and
  `deploy-ecs-blueprint`. Reuse tested components through explicit releases and
  contracts rather than maintaining competing copies.
- [ ] Measure discovery, selection and ordering with generated stack fixtures.
  Separate orchestration, Floci runtime and real AWS deployment measurements.
- [ ] Exercise bounded parallelism, partial failures and retries at an intentional
  scale. Record runner load, API limits, state contention and operational costs.
- [ ] Claim support for hundreds of components only within the measured scope.
- [ ] Build a short walkthrough: tested application → released image → reviewed
  infrastructure change → deployment → drift → recovery → cleanup.
- [ ] Publish a reproducible local demonstration showing provisioning, an intended
  adjustment, injected drift, bounded reconciliation, final verification and cleanup.
  Show the actual Terramate commands and optional Cloud records, clearly labeled local.
- [ ] Retain useful architecture images and recordings, and add links to code,
  workflow runs and dated validation records. Identify personal contributions.
- [ ] Update Automata Life with measured deployment, drift and recovery outcomes,
  known limitations and tradeoffs. Keep scope metrics separate from outcome metrics.
- [ ] Present the project alongside the Kubernetes work as evidence of AWS
  infrastructure operations, with a clear explanation of the skills each demonstrates.

Acceptance: reviewers can follow one complete scenario, reproduce the supported
path and verify each published claim against implementation and evidence.

## Expansion criteria

Additional tools, cloud providers and workloads are optional follow-on work. Extend
the project when a concrete requirement needs them and the existing path remains
reproducible. A GCP/Azure implementation requires its own authentication, provider,
backend, module, workflow and lifecycle validation; swapping module references is
not sufficient evidence of portability.

If adding persistent workloads, define backup, restore and replication behavior
and measure recovery/data loss separately from DNS failover. Do not inherit
stateless recovery claims for a database-backed application.
