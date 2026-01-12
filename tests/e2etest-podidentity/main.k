# e2etest-podidentity - AWS EKS Pod Identity E2E Test
# ====================================================
# Tests IAM role and Pod Identity Association creation for EKS workloads.
#
# This test creates:
# 1. A Network (from aws-network configuration) to provision VPC and subnets
# 2. An AutoEKSCluster using subnet selector to find Network's private subnets
# 3. A PodIdentity that creates IAM role and associates it with the cluster
#
# Prerequisites:
# 1. Create secrets/aws-creds file with AWS credentials in INI format:
#    [default]
#    aws_access_key_id = AKIA...
#    aws_secret_access_key = ...
#
# 2. Run: make e2e
#
# Get resource IDs after first run:
#   kubectl get role <name> -o jsonpath='{.metadata.annotations.crossplane\.io/external-name}'
#   kubectl get podidentityassociation <name> -o jsonpath='{.status.atProvider.id}'

import base64
import file
import datetime
import math
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.ai.com.ops.hops.aws.v1alpha1 as hops

# Read AWS credentials from local file (gitignored)
_creds = file.read("secrets/aws-creds")
_base64_creds = base64.encode(_creds)

# =============================================================================
# Test Configuration
# =============================================================================
_now = str(int(math.floor(datetime.ticks())))
_test_name = "e2e-podid-" + _now
_namespace = "default"
_region = "us-east-2"
_account_id = "034489662075"  # CI test account

# IPAM Pool - from aws-ipam e2e test
# Get pool IDs: aws ec2 describe-ipam-pools --query 'IpamPools[*].[IpamPoolId,AddressFamily,Description]' --output table
_ipv4_private_pool_id = "ipam-pool-0607416fa3707147a"

# =============================================================================
# IAM Policy for PodIdentity test
# =============================================================================
_policy = """{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::e2e-test-bucket",
                "arn:aws:s3:::e2e-test-bucket/*"
            ]
        }
    ]
}"""

_items = [
    metav1alpha1.E2ETest {
        metadata.name = "podidentity"
        spec = {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "None"
            }
            defaultConditions = ["Ready"]
            timeoutSeconds = 5400  # 90 minutes for EKS cluster creation
            cleanupTimeoutSeconds = 1800  # 30 minutes for cleanup
            skipDelete = False

            # initResources: Install dependency Configuration packages
            initResources = [
                # aws-network Configuration package (provides Network XRD)
                {
                    apiVersion = "pkg.crossplane.io/v1"
                    kind = "Configuration"
                    metadata = {
                        name = "aws-network"
                    }
                    spec = {
                        package = "ghcr.io/hops-ops/aws-network:v0.5.0"
                    }
                }
                # aws-auto-eks-cluster Configuration package (provides AutoEKSCluster XRD)
                {
                    apiVersion = "pkg.crossplane.io/v1"
                    kind = "Configuration"
                    metadata = {
                        name = "aws-auto-eks-cluster"
                    }
                    spec = {
                        package = "ghcr.io/hops-ops/aws-auto-eks-cluster:v0.1.0"
                    }
                }
            ]

            # extraResources: Credentials and ProviderConfig (not deleted during cleanup)
            extraResources = [
                # AWS credentials secret
                {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = "aws-creds"
                        namespace = _namespace
                    }
                    data = {
                        creds = _base64_creds
                    }
                }
                # AWS ProviderConfig using Secret credentials
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = _namespace
                    }
                    spec = {
                        credentials = {
                            source = "Secret"
                            secretRef = {
                                namespace = _namespace
                                name = "aws-creds"
                                key = "creds"
                            }
                        }
                    }
                }
            ]

            # manifests: All XRs that need cleanup (Network, AutoEKSCluster, PodIdentity)
            manifests = [
                # 1. Network - provides VPC and subnets using IPAM
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "Network"
                    metadata = {
                        name = _test_name
                        namespace = _namespace
                    }
                    spec = {
                        region = _region
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        tags = {
                            "e2etest" = "true"
                            "test-run" = _now
                        }
                        # Use IPAM to auto-allocate VPC CIDR
                        ipam = {
                            ipv4 = {
                                enabled = True
                                poolId = _ipv4_private_pool_id
                                netmaskLength = 16
                            }
                        }
                        subnetLayout = {
                            availabilityZones = ["a", "b"]
                            public = {
                                enabled = True
                                netmaskLength = 24
                            }
                            private = {
                                enabled = True
                                netmaskLength = 20
                            }
                        }
                        # Disable NAT to speed up test
                        nat = {
                            enabled = False
                        }
                    }
                }

                # 2. AutoEKSCluster - uses Network's private subnets
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "AutoEKSCluster"
                    metadata = {
                        name = _test_name
                        namespace = _namespace
                    }
                    spec = {
                        clusterName = _test_name
                        region = _region
                        accountId = _account_id
                        version = "1.34"
                        subnetSelector = {
                            matchLabels = {
                                "hops.ops.com.ai/network" = _test_name
                                "hops.ops.com.ai/tier" = "private"
                            }
                        }
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        tags = {
                            "e2etest" = "true"
                            "test-run" = _now
                        }
                        publicAccess = True
                        nodeConfig = {
                            enabled = True
                        }
                        oidc = {
                            enabled = True
                        }
                    }
                }

                # 3. PodIdentity - creates IAM role and Pod Identity Association
                hops.PodIdentity {
                    metadata = {
                        name = _test_name
                        namespace = _namespace
                    }
                    spec = {
                        clusterName = _test_name
                        region = _region
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        serviceAccount = {
                            namespace = "kube-system"
                            name = "e2e-test-sa"
                        }
                        inlinePolicy = [
                            {
                                name = "e2e-test-policy"
                                policy = _policy
                            }
                        ]
                        tags = {
                            "e2etest" = "true"
                            "test-run" = _now
                        }
                    }
                }
            ]
        }
    }
]

items = _items
