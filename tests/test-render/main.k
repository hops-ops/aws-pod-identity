
import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-pod-identity-render-full"
        spec= {
            assertResources: [
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "Role"
                    metadata: {
                        name: "loki-custom-role"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "shared-aws-provider"
                        }
                        forProvider: {
                            name: "loki-custom-role"
                            managedPolicyArns: [
                                "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
                            ]
                            permissionsBoundary: "arn:aws:iam::123456789012:policy/eks-permissions-boundary"
                            inlinePolicy: [
                                {
                                    name: "loki-storage"
                                },
                                {
                                    name: "allow-read-secrets"
                                }
                            ]
                            tags: {
                                environment: "demo"
                                hops: "true"
                            }
                        }
                    }
                },
                {
                    apiVersion: "eks.aws.m.upbound.io/v1beta1"
                    kind: "PodIdentityAssociation"
                    metadata: {
                        name: "cluster-x-example"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "shared-aws-provider"
                        }
                        forProvider: {
                            clusterName: "cluster-x"
                            namespace: "observability"
                            region: "us-west-2"
                            roleArnSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "aws.hops.ops.com.ai/pod-identity": "example"
                                }
                            }
                            serviceAccount: "loki"
                        }
                    }
                }
            ]
            compositionPath: "apis/podidentities/composition.yaml"
            xrPath: "examples/podidentities/full-schema.yaml"
            xrdPath: "apis/podidentities/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    },
    metav1alpha1.CompositionTest{
        metadata.name: "test-pod-identity-render-minimal"
        spec= {
            assertResources: [
                {
                    apiVersion: "iam.aws.m.upbound.io/v1beta1"
                    kind: "Role"
                    metadata: {
                        name: "cluster-x-example"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
                            name: "cluster-x-example"
                            inlinePolicy: [
                                {
                                    name: "default"
                                }
                            ]
                            tags: {
                                hops: "true"
                            }
                        }
                    }
                },
                {
                    apiVersion: "eks.aws.m.upbound.io/v1beta1"
                    kind: "PodIdentityAssociation"
                    metadata: {
                        name: "cluster-x-example"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
                            clusterName: "cluster-x"
                            namespace: "observability"
                            region: "us-west-2"
                            roleArnSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "aws.hops.ops.com.ai/pod-identity": "example"
                                }
                            }
                            serviceAccount: "loki"
                        }
                    }
                }
            ]
            compositionPath: "apis/podidentities/composition.yaml"
            xrPath: "examples/podidentities/example-minimal.yaml"
            xrdPath: "apis/podidentities/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    }
]
items= _items
