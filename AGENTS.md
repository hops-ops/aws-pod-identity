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

- `clusterName` seeds providerConfig defaults. When unset, `aws.providerConfig` falls back to this value, otherwise `"default"`.
- `aws` groups all AWS inputs. It exposes `providerConfig` plus a nested `config` with IAM-specific settings.
- Optional flags (for example `policy`) should be explicit. If a value must be provided, let the template fail rather than silently default.
- AWS tags always merge caller-supplied tags with the default `{"hops": "true"}` map.

The composite accepts:

- `accountId` (string): AWS account that owns the IAM role.
- `name` (string): Logical name used by IAM resources.
- `namespace` and `serviceAccountName`: Target Kubernetes service account.
- `rolePrefix` and `policyPrefix`: Optional prefixes for IAM resources.
- `permissionsBoundary`: Optional IAM permissions boundary ARN.
- `policy`: Inline JSON policy document attached to the IAM role.
- `tags`: Free-form AWS tags (merged with the default hops tag).
- `region`: AWS region hosting the EKS cluster.

## Rendering Pipeline

- `00-variables.yaml.gotmpl` hoists shared values (`clusterName`, provider configs, deletion policy) into scope. Always default optional values with `default`.
- `01-variables-aws.yaml.gotmpl` extracts AWS-specific inputs such as account ID, region, prefixes, and tag maps.
- Resource templates (`10-iam-role.yaml.gotmpl`, `11-iam-policy.yaml.gotmpl`, etc.) consume only previously declared variables. Leave numeric gaps so future inserts remain readable.
- Use straightforward string interpolation for names; avoid complex ternaries and keep renovate-friendly chart declarations out of variables.

## AWS Integrations

- IAM roles assume the pods.amazonaws.com principal required by EKS Pod Identity. Do not revert to legacy IRSA trust policies.
- The inline policy is passed through verbatim from `spec.policy`. Validate JSON before committing updates.
- IAM resources use `rolePrefix` / `policyPrefix` combined with `clusterName` and `name` to keep identities unique.
- Pod Identity associations reference the IAM role ARN directly—prefer explicit names over selectors when the API allows it.

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
