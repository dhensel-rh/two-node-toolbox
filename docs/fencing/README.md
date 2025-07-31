# Two Node with Fencing (TNF)

> Note to deploy a TNF cluster for development please see the [dev deployment guide](../../deploy/openshift-clusters/README.md).

Traditionally, achieving High Availability for the control plane in OpenShift Container Platform requires a minimum of three full control plane (master) nodes to maintain etcd quorum. The two-node with fencing configuration introduces an alternative topology that allows for HA with a reduced footprint and lower hardware costs.

## What is fencing?

Fencing is the process of isolating or powering off malfunctioning or unresponsive nodes to prevent them from causing further harm, such as data corruption or the creation of divergent datasets. This is a critical component for maintaining quorum.
-  **For TNF, etcd quorum is the main objective** and the primary mechanism to power off an unreachable node is through RedFish compatible Baseboard Management Controllers (BMCs), which will be used by Pacemaker.

## Purpose and Motivation

The primary motivation for fencing mechanism is to provide an even more **economical solution for HA deployments at the edge**. Customers at edge locations often require redundancy but also need a low cost option to achieve it. This configuration allows organizations to deploy OpenShift with **only two regular-sized control plane nodes**. This helps maintain HA while keeping compute costs down. Extra components needed are supplied in the form of software. 

## High level overview

The TNF architecture leverages **traditional high-availability concepts and technologies to manage critical OpenShift components**, specifically <u>CRI-O, Kubelet, and Etcd</u>. This is achieved through the use of RHEL-HA components: <u>Pacemaker and Corosync</u>.
- **Pacemaker** acts as the "brain," providing HA capabilities and managing resources through resource agents and recovery functions through fencing agents. Corosync provides the necessary networking and messaging components.
  - **Etcd management by Pacemaker** is central to maintaining quorum in a two-node setup. Unlike normal OpenShift clusters where etcd runs as pods within the openshift-etcd namespace, in TNF, **Pacemaker runs etcd using Podman containers outside of the cluster**'s direct management.
- **Corosync** is a core component of the RHEL-HA stack, working alongside Pacemaker. It is an open-source project that provides essential networking and messaging components for the cluster. 
  - **Corosync is responsible for providing a consistent view of cluster membership, reliable ordered messaging, and flexible quorum capabilities**. In a two-node TNF cluster, Corosync **ensures that the nodes** can form a "C-quorum" (Corosync quorum) by establishing **membership with each other**
---
## Installation and Initialization 
>Note: This process is handled via the provided [dev deployment guide](../../deploy/openshift-clusters/README.md), but is described here for your information

 The installation process starts with an initial boostrap node, which will then reboot into one of two final control plane nodes. A critical step involves the Cluster Etcd Operator (CEO), which, upon detecting the DualReplica control plane topology, triggers a TNF controller job. This controller runs pcs commands to initialize Pacemaker and configure the podman-etcd resource agent on both nodes. CEO then relinquishes control of etcd by setting specific flags, causing etcd containers to be removed from static pod configs and immediately recreated by Pacemaker using Podman. Fencing credentials, collected via the install-config (specifically RedFish details like address, username, and password), are made available to the nodes and used by Pacemaker to set up fencing. The Bare Metal Operator (BMO) is also adjusted to prevent power management of control-plane nodes in this topology to avoid conflicts with Pacemaker.

## Disruption handling
- **Recovery and State**: After a node reboots, it re-establishes membership with the etcd cluster, initially as a learner, and then becomes a fully joined member. The cluster ensures stability by maintaining a consistent cluster ID. While the cluster can operate in a degraded single-node state if one node fails, this is not recommended for long-term health, as it impacts operators and operations dependent on multiple nodes. See below for handling of graceful and ungraceful disruptions.
---
 - **Graceful Disruption Events**: Support as of version 4.19 of Openshift
 Pacemaker can detect when a node is gracefully rebooting, such as during upgrades, Machine Config Operator (MCO) reboots, or user-initiated shutdowns. In such cases, **Pacemaker intercepts the reboot command, removes the node from the etcd cluster**, allowing the API server to continue serving requests as a "cluster-of-one" **until the reboot succeeds and the node can resync and rejoin.**
- **Ungraceful Disruption Events**: Supported for Openshift 4.20
For node crashes or network outages where a node cannot signal its departure, **Pacemaker will fence the unreachable node by powering it off** via a fencing agent that communicates **with the node's BMC**. Once fenced, Pacemaker forces a restart of etcd on the surviving node as a "cluster-of-one" with a new cluster ID. When the failed node restarts, it detects the updated cluster ID, discards its old database, and resyncs to rejoin the cluster.

## Limitations and Considerations
- **Technology Preview**: The fencing configuration is a Technology Preview feature and **not supported with Red Hat production service level agreements (SLAs)**.
- **Bare Metal Only**: Initially, support for installing OpenShift with 2 control plane nodes and fencing is **limited to bare metal**. Cloud deployments are not supported for this configuration at this time due to scope and validation practicality.
- **Hardware requirements**: The fencing mechanism requires the nodes to be outfitted with a RedFish compatible BMC. It is recommended that the fencing network is isolated from the main cluster network, but it is not mandatory. 

