# config-pod-identity

`config-pod-identity` is a Crossplane configuration package that provisions IAM roles, policies, and Amazon EKS Pod Identity associations for Kubernetes service accounts. It publishes the `XPodIdentity` composite resource definition so platform teams can grant AWS permissions to workloads without hand-crafting IAM resources.

## Features

- Creates IAM roles with the EKS Pod Identity trust policy.
- Attaches inline IAM policies supplied by the caller.
- Supports optional `rolePrefix`, `policyPrefix`, and permissions boundaries.
- Creates `PodIdentityAssociation` resources that map IAM roles to Kubernetes service accounts.
- Ships with automation for validation, testing, and package publishing.

## Prerequisites

- An Amazon EKS cluster running in the target AWS account.
- Crossplane installed in the cluster.
- Crossplane providers:
  - `provider-aws-iam` (≥ v2.1.1)
  - `provider-aws-eks` (≥ v2.1.1)
- Crossplane function:
  - `function-auto-ready` (≥ v0.5.1)

## Installing the Package

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: config-pod-identity
spec:
  package: ghcr.io/hops-ops/config-pod-identity:latest
  packagePullSecrets:
    - name: ghcr
  skipDependencyResolution: true
```

## Example Composite

```yaml
apiVersion: hops.ops.com.ai/v1alpha1
kind: XPodIdentity
metadata:
  name: example-pod-identity
spec:
  clusterName: cluster-x
  accountId: "123456789012"
  region: us-west-2
  name: loki
  permissionsBoundary: "arn:aws:iam::123456789012:policy/eks-permissions-boundary"
  tags:
    workload: example
  serviceAccount:
    namespace: observability
    name: loki
  policy: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:PutObject"
          ],
          "Resource": [
            "arn:aws:s3:::example-loki-chunks",
            "arn:aws:s3:::example-loki-chunks/*"
          ]
        }
      ]
    }
```

## Local Development

- `make render` – render the default example.
- `make validate` – run Crossplane schema validation.
- `make test` – execute `up test` regression tests.
- `make publish tag=<version>` – build and push the configuration package.

Before publishing, ensure CI workflows in `.github/` remain in sync with `.gitops/` automation.

## License

Apache-2.0. See [LICENSE](LICENSE) for details.
