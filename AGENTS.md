# Pod Identity Config Agent Guide

This repository publishes the `PodIdentity` Crossplane configuration package. Use this guide whenever you change schemas, templates, automation, or release tooling here.

## Repository Layout

- `apis/`: CRDs and composition files for `PodIdentity`. Treat this directory as the source of truth for the published package.
- `examples/`: Example composite resources. Keep each file renderable with the `make render-example` target and refresh whenever the schema changes.
- `functions/render/`: Go-template rendering pipeline. Files are processed in lexical order; keep the `00-`, `10-`, `20-` naming convention so related resources stay grouped.
- `.github/` and `.gitops/`: CI and GitOps automation. Maintain structural parity between them and only tune repo-specific defaults (registry, image names, etc.).
- Use `configuration-aws-irsa` as the upstream reference when updating `.github/` and `.gitops/`. Copy workflow changes from there first, then adjust paths (examples, API dirs) specific to PodIdentity so automation stays consistent across repos.
- `_output/`: Local render artifacts created by `up` commands.
- `.up/`: Cached build metadata for `up` tooling. Safe to remove via `make clean`.
- `tests/`: Regression tests consumed by `up test`.
- `Makefile`: Entry point for render, validate, test, and release workflows.

## PodIdentity Contract

`apis/podidentities` defines the composite schema and composition. The contract mirrors `configuration-aws-irsa`:

- The XRD scope is `Namespaced`, so example composites must include `metadata.namespace`.
- `spec.clusterName` seeds providerConfig defaults. When unset, `aws.providerConfig` falls back to this value, otherwise `"default"`.
- Inputs live directly under `spec.*`; do not reintroduce a `parameters` wrapper.
- Optional flags (for example `permissionsBoundaryArn`) should be explicit. If a value must be provided, let the template fail rather than silently default.
- The rendering function currently uses `required` to enforce `region` plus `serviceAccount.{name,namespace}`; keep those checks intact so misconfigured callers fail fast.
- AWS tags always merge caller-supplied tags with the default `{"hops": "true"}` map.

The composite accepts:

- `region` (string): AWS region hosting the EKS cluster.
- `clusterName`, `clusterNameRef`, or `clusterNameSelector`: Identify which EKS cluster to bind.
- `serviceAccount` (object): Target Kubernetes service account (name + namespace).
- `inlinePolicy` (array): Exclusive inline IAM policies applied to the role.
- `managedPolicyArns` (set of strings): Managed policy ARNs to attach.
- `permissionsBoundaryArn` (string): Optional IAM permissions boundary.
- `rolePrefix` (string): Optional string prepended to the generated IAM role name.
- `roleNameOverride` (string): Optional AWS role name override. `roleName` remains a backwards-compatible alias but prefer the new field.
- `aws.providerConfig` (string): Optional provider config override; falls back to cluster name or `default`.
- `tags` (map): Free-form AWS tags (merged with the default hops tag).

## Rendering Pipeline

- `00-desired-values.yaml.gotmpl` hoists shared values (`clusterName`, provider configs, IAM naming, service account data) into scope. Always default optional values with `default`.
- `00-observed-values.yaml.gotmpl` mirrors the aws-irsa pattern by normalising `.observed.resources` and deriving readiness/ARN data for status projection. If you add new resources, teach this file how to surface their readiness/IDs.
- Resource templates (`10-iam-role.yaml.gotmpl`, `20-pod-identity-association.yaml.gotmpl`, etc.) consume only previously declared variables. Leave numeric gaps so future inserts remain readable.
- `30-usages.yaml.gotmpl` creates `protection.crossplane.io/Usage` links once both the IAM role and PodIdentityAssociation report Ready. Keep any new resources wired into observed values first so usages only render after dependencies exist.
- `99-status.yaml.gotmpl` writes `status.podIdentity` using the observed data. Keep it lean and extend the CRD schema (or ensure `x-kubernetes-preserve-unknown-fields`) before adding new fields.
- Use straightforward string interpolation for names; avoid complex ternaries and keep renovate-friendly chart declarations out of desired values.

## AWS Integrations

- IAM roles assume the pods.amazonaws.com principal required by EKS Pod Identity. Do not revert to legacy IRSA trust policies.
- Inline policies are passed through verbatim from `spec.inlinePolicy[*].policy`. Validate JSON before committing updates.
- IAM resources default the AWS role name to `<clusterName>-<metadata.name>` (or whichever pieces are provided), optionally prefixed by `rolePrefix`, unless overridden by `roleNameOverride`/`roleName`. If inputs are omitted entirely, the XR name becomes the fallback.
- PodIdentityAssociation metadata names follow the same `<clusterName>-<metadata.name>` base, so avoid introducing suffixes like `-pod-identity`.
- Resource metadata names should match the XR (or another meaningful identifier) without repeating the resource kind—no `-role`, `-policy`, etc.
- Both IAM Role and PodIdentityAssociation set `providerConfigRef.kind: ProviderConfig`; keep that to match other configs.
- Pod Identity associations resolve the IAM role using the shared `aws.hops.ops.com.ai/pod-identity` label—prefer labels over explicit ARNs to keep resources composable.

## Development Workflow

- `make render` renders the main example.
- `make validate` runs Crossplane validation against the composition and examples.
- `make test` executes regression tests under `tests/` via `up test`. It needs Docker access; if the sandbox blocks `/var/run/docker.sock`, note that in your handoff.
- `make publish tag=<version>` builds and pushes a package revision. Ensure CI workflow versions match `.github/workflows`.
- Run `make clean` if `_output/` or `.up/` appear stale.

## Automation Notes

- Renovate monitors `.yaml` and `.yaml.gotmpl` files. Extend `renovate.json` here if new dependency managers are introduced.
- Keep `.github/` and `.gitops/` workflows updated together so automation stays consistent between CI and GitOps deployments.
- Document behavior changes or new inputs in `README.md`, and refresh example manifests to reflect new defaults. The README example mirrors the user request (`configuration-aws-eks-pod-identity`); keep it updated when defaults shift.
