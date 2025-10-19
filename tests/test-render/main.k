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
                        name: "podid-cluster-x-loki"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
                            permissionsBoundary: "arn:aws:iam::123456789012:policy/eks-permissions-boundary"
                            tags: {
                                environment: "demo"
                                hops: "true"
                            }
                        }
                    }
                },
                {
                    apiVersion: "iam.aws.upbound.io/v1beta1"
                    kind: "Policy"
                    metadata: {
                        name: "podid-cluster-x-loki"
                    }
                    spec: {
                        forProvider: {
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
                        name: "cluster-x-observability-loki-pod-identity"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
                            clusterName: "cluster-x"
                            namespace: "observability"
                            region: "us-west-2"
                            roleArn: "arn:aws:iam::123456789012:role/podid-cluster-x-loki"
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
                        name: "cluster-x-loki"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
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
                        name: "cluster-x-observability-loki-pod-identity"
                    }
                    spec: {
                        providerConfigRef: {
                            name: "cluster-x"
                        }
                        forProvider: {
                            clusterName: "cluster-x"
                            namespace: "observability"
                            region: "us-west-2"
                            roleArn: "arn:aws:iam::123456789012:role/cluster-x-loki"
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
