# TWO-NODE TOOLBOX
## Introduction
This repository contains tools to deploy testing or development two-node Openshift clusters. Most lifecycle operations can be performed directly from the [deploy](deploy/) folder using `make`. Its README file and `make help` will show you the available options.

## Creating a dev environment
The `openshift-cluster` tools expect a valid RHEL hypervisor to host all necessary VMs to create and set up the cluster.
If you don't already have one available, the [aws-hypervisor](deploy/aws-hypervisor/README.md) folder provides instructions and tools to automatically create this base host in AWS. 

Once the hypervisor is setup, you can use the [deployment tools](deploy/openshift-clusters/README.md) to create specific OpenShift clusters within that newly provisioned host, or on your own one. For AWS-hosted environments, quick deployment options are available via `make fencing-ipi` and `make arbiter-ipi` commands directly from the deploy folder.

Provided you have followed the instructions on both of these READMEs for unattended installation, you can create the instance and install OpenShift on it with one command. For example `make deploy arbiter-ipi` will create an Arbiter topology OpenShift cluster using the IPI method.

## Two-node available topologies
[Two-Node with Arbiter](docs/arbiter/README.md) and [Two-Node with Fencing](docs/fencing/README.md) topologies are available. You can read more on them in the [docs](docs) folder.