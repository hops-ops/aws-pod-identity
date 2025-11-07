import models.com.tech.unbounded.hops.v1alpha1 as hopsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-pod-identity-render-full"
        spec= {
            assertResources: [
                {
                    apiVersion: "iam.aws.upbound.io/v1beta1"
                    kind: "Role"
                    metadata: {
                        name: "example-pod-identity-role"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
                            name: "podid-cluster-x-loki"
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
                    apiVersion: "eks.aws.upbound.io/v1beta1"
                    kind: "PodIdentityAssociation"
                    metadata: {
                        name: "example-pod-identity-pod-identity"
                    }
                    spec: {
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
                                    "aws.hops.ops.com.ai/pod-identity": "example-pod-identity"
                                }
                            }
                            serviceAccount: "loki"
                        }
                    }
                }
            ]
            compositionPath: "apis/xpodidentities/composition.yaml"
            xrPath: "examples/xpodidentities/full-schema.yaml"
            xrdPath: "apis/xpodidentities/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    },
    metav1alpha1.CompositionTest{
        metadata.name: "test-pod-identity-render-minimal"
        spec= {
            assertResources: [
                {
                    apiVersion: "iam.aws.upbound.io/v1beta1"
                    kind: "Role"
                    metadata: {
                        name: "example-pod-identity-role"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
                            name: "cluster-x"
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
                    apiVersion: "eks.aws.upbound.io/v1beta1"
                    kind: "PodIdentityAssociation"
                    metadata: {
                        name: "example-pod-identity-pod-identity"
                    }
                    spec: {
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
                                    "aws.hops.ops.com.ai/pod-identity": "example-pod-identity"
                                }
                            }
                            serviceAccount: "loki"
                        }
                    }
                }
            ]
            compositionPath: "apis/xpodidentities/composition.yaml"
            xrPath: "examples/xpodidentities/example-minimal.yaml"
            xrdPath: "apis/xpodidentities/definition.yaml"
            timeoutSeconds: 120
            validate: True
        }
    }
]
items= _items
