# Pod Identity Config Agent Guide

This repository publishes the `XPodIdentity` Crossplane configuration package. Use this guide whenever you change schemas, templates, automation, or release tooling here.

## Repository Layout

- `apis/`: CRDs and composition files for `XPodIdentity`. Treat this directory as the source of truth for the published package.
- `examples/`: Example composite resources. Keep each file renderable with the `make render-example` target and refresh whenever the schema changes.
- `functions/render/`: Go-template rendering pipeline. Files are processed in lexical order; keep the `00-`, `10-`, `20-` naming convention so related resources stay grouped.
- `.github/` and `.gitops/`: CI and GitOps automation. Maintain structural parity between them and only tune repo-specific defaults (registry, image names, etc.).
- `_output/`: Local render artifacts created by `up` commands.
- `.up/`: Cached build metadata for `up` tooling. Safe to remove via `make clean`.
- `tests/`: Regression tests consumed by `up test`.
- `Makefile`: Entry point for render, validate, test, and release workflows.

## XPodIdentity Contract

`apis/xpodidentities` defines the composite schema and composition. The contract mirrors other hops configs:

- `spec.parameters.clusterName` seeds providerConfig defaults. When unset, `providerConfigName` falls back to this value, otherwise `"default"`.
- Inputs are grouped under `spec.parameters` to mirror other Upbound configurations.
- Optional flags (for example `permissionsBoundaryArn`) should be explicit. If a value must be provided, let the template fail rather than silently default.
- AWS tags always merge caller-supplied tags with the default `{"hops": "true"}` map.

The composite accepts:

- `region` (string): AWS region hosting the EKS cluster.
- `clusterName`, `clusterNameRef`, or `clusterNameSelector`: Identify which EKS cluster to bind.
- `serviceAccount` (object): Target Kubernetes service account (name + namespace).
- `inlinePolicy` (array): Exclusive inline IAM policies applied to the role.
- `managedPolicyArns` (set of strings): Managed policy ARNs to attach.
- `permissionsBoundaryArn` (string): Optional IAM permissions boundary.
- `roleName` (string): Optional AWS role name override.
- `providerConfigName` (string): Optional provider config override; falls back to cluster name or `default`.
- `tags` (map): Free-form AWS tags (merged with the default hops tag).

## Rendering Pipeline

- `00-variables.yaml.gotmpl` hoists shared values (`clusterName`, provider configs, deletion policy) into scope. Always default optional values with `default`.
- `01-variables-aws.yaml.gotmpl` extracts AWS-specific inputs such as region, inline policies, and tag maps.
- Resource templates (`10-iam-role.yaml.gotmpl`, `20-pod-identity-association.yaml.gotmpl`, etc.) consume only previously declared variables. Leave numeric gaps so future inserts remain readable.
- Use straightforward string interpolation for names; avoid complex ternaries and keep renovate-friendly chart declarations out of variables.

## AWS Integrations

- IAM roles assume the pods.amazonaws.com principal required by EKS Pod Identity. Do not revert to legacy IRSA trust policies.
- Inline policies are passed through verbatim from `spec.parameters.inlinePolicy[*].policy`. Validate JSON before committing updates.
- IAM resources default the AWS role name from the cluster or XR name unless overridden by `roleName`.
- Pod Identity associations resolve the IAM role using the shared `aws.hops.ops.com.ai/pod-identity` label—prefer labels over explicit ARNs to keep resources composable.

## Development Workflow

- `make render` renders the main example.
- `make validate` runs Crossplane validation against the composition and examples.
- `make test` executes regression tests under `tests/` via `up test`.
- `make publish tag=<version>` builds and pushes a package revision. Ensure CI workflow versions match `.github/workflows`.
- Run `make clean` if `_output/` or `.up/` appear stale.

## Automation Notes

- Renovate monitors `.yaml` and `.yaml.gotmpl` files. Extend `renovate.json` here if new dependency managers are introduced.
- Keep `.github/` and `.gitops/` workflows updated together so automation stays consistent between CI and GitOps deployments.
- Document behavior changes or new inputs in `README.md`, and refresh example manifests to reflect new defaults.
