# AWS EKS Pod Identity

A Crossplane configuration that provisions IAM roles and EKS Pod Identity associations for Kubernetes service accounts. Grant AWS permissions to workloads without hand-crafting IAM resources.

## Getting Started

### Prerequisites

- Amazon EKS cluster with Pod Identity agent installed
- Crossplane installed in your cluster
- Required providers: `provider-aws-iam` (≥ v2.1.1), `provider-aws-eks` (≥ v2.1.1)

### Installation

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: aws-pod-identity
spec:
  package: ghcr.io/hops-ops/aws-pod-identity:latest
  packagePullSecrets:
    - name: ghcr
```

### Minimal Example

Create a Pod Identity for a service account with basic S3 read access:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: PodIdentity
metadata:
  name: my-app
  namespace: my-namespace
spec:
  clusterName: my-cluster
  region: us-west-2
  serviceAccount:
    name: my-app
    namespace: my-namespace
  inlinePolicy:
    - name: s3-read
      policy: |
        {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Action": ["s3:GetObject"],
                "Resource": ["arn:aws:s3:::my-bucket/*"]
            }]
        }
```

This creates:
- An IAM role with EKS Pod Identity trust policy
- A Pod Identity Association linking the role to your service account

## Growing

### Adding Managed Policies

Attach AWS managed policies alongside inline policies:

```yaml
spec:
  managedPolicyArns:
    - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
    - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

### Custom Role Naming

Control the IAM role name:

```yaml
spec:
  rolePrefix: podid-        # Prepends to auto-generated name
  roleNameOverride: my-role # Or specify exact name
```

### Permissions Boundaries

Enforce security boundaries on the IAM role:

```yaml
spec:
  permissionsBoundaryArn: arn:aws:iam::123456789012:policy/eks-permissions-boundary
```

### Custom Labels

Add labels to all managed resources for tracking and organization:

```yaml
spec:
  labels:
    team: platform
    app: loki
    cost-center: engineering
```

Default labels are automatically applied:
- `hops.ops.com.ai/managed: "true"`
- `hops.ops.com.ai/podidentity: <name>`

### Custom Provider Configuration

Use a specific AWS provider config:

```yaml
spec:
  providerConfigRef:
    name: shared-aws-provider
```

## Enterprise Scale

### Multiple Environments

Use namespace isolation with provider configs per environment:

```yaml
# Production
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: PodIdentity
metadata:
  name: my-app
  namespace: production
spec:
  clusterName: prod-cluster
  providerConfigRef:
    name: aws-prod
  labels:
    environment: production
  ...

# Staging
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: PodIdentity
metadata:
  name: my-app
  namespace: staging
spec:
  clusterName: staging-cluster
  providerConfigRef:
    name: aws-staging
  labels:
    environment: staging
  ...
```

### Orphan Protection

Prevent accidental AWS resource deletion by removing Delete from management policies:

```yaml
spec:
  managementPolicies:
    - Create
    - Observe
    - Update
    - LateInitialize
```

With this configuration, deleting the PodIdentity claim will NOT delete the underlying AWS resources.

## Import Existing

Adopt pre-existing IAM roles and Pod Identity associations into Crossplane management.

### Import Pattern

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: PodIdentity
metadata:
  name: imported-workload
  namespace: default
spec:
  clusterName: my-cluster
  region: us-west-2
  # Orphan policy - resources persist after claim deletion
  managementPolicies:
    - Create
    - Observe
    - Update
    - LateInitialize
  serviceAccount:
    namespace: monitoring
    name: prometheus
  # Import existing IAM role by name
  role:
    externalName: my-existing-role
  # Import existing association by ID
  association:
    externalName: a-0123456789abcdef0
  inlinePolicy:
    - name: monitoring
      policy: |
        ...
```

### Getting External Names

After initial creation (or to find existing resources):

```bash
# IAM Role external name (the role name)
kubectl get role <name> -o jsonpath='{.metadata.annotations.crossplane\.io/external-name}'

# Pod Identity Association ID
kubectl get podidentityassociation <name> -o jsonpath='{.status.atProvider.id}'
```

## Development

```bash
make render:all   # Render all examples
make validate:all # Validate against schemas
make test         # Run unit tests
make e2e          # Run E2E tests
make publish tag=v1.0.0  # Build and push package
```

## License

Apache-2.0
