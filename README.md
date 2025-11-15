# configuration-aws-pod-identity

`configuration-aws-pod-identity` is a Crossplane configuration package that provisions IAM roles, policies, and Amazon EKS Pod Identity associations for Kubernetes service accounts. It publishes the `PodIdentity` composite resource definition so platform teams can grant AWS permissions to workloads without hand-crafting IAM resources.

## Features

- Creates IAM roles with the EKS Pod Identity trust policy.
- Attaches inline IAM policies supplied by the caller and optional managed policy ARNs.
- Supports IAM role naming conventions through `rolePrefix` or explicit `roleNameOverride` (with `roleName` kept for backwards compatibility).
- Supports optional permissions boundaries and custom provider configs.
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
  name: configuration-aws-pod-identity
spec:
  package: ghcr.io/hops-ops/configuration-aws-pod-identity:latest
  packagePullSecrets:
    - name: ghcr
  skipDependencyResolution: true
```

## Example Composite

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: PodIdentity
metadata:
  name: configuration-aws-eks-pod-identity
  namespace: example-env
spec:
  region: us-west-2
  clusterName: my-cluster
  managementPolicies:
    - "*"
  managedPolicyArns:
    - "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  rolePrefix: podid-
  roleNameOverride: loki-custom-role
  inlinePolicy:
    - name: allow-kms-describe
      policy: |
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "kms:DescribeKey"
                    ],
                    "Resource": "*"
                }
            ]
        }
  serviceAccount:
    name: my-controller
    namespace: kube-system
```

## Local Development

- `make render` – render the default example.
- `make validate` – run Crossplane schema validation.
- `make test` – execute `up test` regression tests.
- `make publish tag=<version>` – build and push the configuration package.

Before publishing, ensure CI workflows in `.github/` remain in sync with `.gitops/` automation.

## License

Apache-2.0. See [LICENSE](LICENSE) for details.
