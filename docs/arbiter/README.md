# Two Node Arbiter (TNA)

> Note to deploy a TNA cluster for development please see the [dev deployment guide](../../deploy/openshift-clusters/README.md).

Traditionally, achieving High Availability for the control plane in OpenShift Container Platform requires a minimum of three full control plane (master) nodes to maintain etcd quorum. The arbiter node introduces an alternative topology that allows for HA with a reduced footprint and potentially lower hardware costs.

## What is an Arbiter?

An Arbiter node is a special type of control plane node that participates in control plane quorum decisions. Unlike a standard control plane node, the arbiter node is designed to be a **lower-cost, co-located machine** that **does not run the full set of control plane services**. It has a specific **new node role type**: `node-role.kubernetes.io/arbiter`.

The main high level components that the Arbiter runs are:

- Etcd Member Pods
- Networking Pods
- Machine Config Pods

## Purpose and Motivation

The primary motivation for the arbiter node is to provide a more **economical solution for HA deployments at the edge**. Customers at edge locations often require redundancy but need a lower-cost option to achieve the three nodes necessary for etcd quorum. This configuration allows organizations to deploy OpenShift with **only two regular-sized control plane nodes and one lower-cost arbiter node**. This helps maintain HA while keeping compute costs down.

## How it Functions (High Level)

- **Role**: The arbiter node has the dedicated role `node-role.kubernetes.io/arbiter`.
- **Quorum**: The arbiter node participates in the control plane quorum to ensure HA. The goal is for HA with a 2+1 arbiter node cluster to **match the HA guarantees of a conventional 3-node cluster** deployment.
- **Workloads**: The arbiter node is intended to run only **critical components necessary for maintaining HA**, such as the Machine Config Daemon (MCD), monitoring, and networking. Other platform pods or non-critical applications **should not be scheduled** on the arbiter node by default.
- **Tainting**: The arbiter node is **tainted** (`node-role.kubernetes.io/arbiter=NoSchedule`) to prevent non-critical applications from being scheduled on it. Deployments **can be scheduled** on the arbiter node only if they have the **proper tolerations** in place or explicitly define the arbiter node in their spec.
- **Hardware**: The hardware requirements for the arbiter node are expected to be **lower than regular control plane nodes** in terms of both cost and performance.
- **Etcd**: The etcd operator is updated to deploy its operands on both `master` and `arbiter` node roles. The cluster-etcd-operator (CEO) watches for both master and arbiter nodes to update configuration, such as the list of etcd member IPs.

## Limitations and Considerations

- **Technology Preview**: The arbiter node configuration is a Technology Preview feature and **not supported with Red Hat production service level agreements (SLAs)**.
- **Bare Metal Only**: Initially, support for installing OpenShift with 2 control plane nodes and 1 arbiter node is **limited to bare metal**. Cloud deployments are not supported for this configuration at this time due to scope and validation practicality.
- **Placement**: The arbiter node must be **local** to the cluster; running it offsite is not a goal at this time.
- **Workload Restrictions**: The arbiter is **never intended to be a worker node**. Only specific, critical components should run on it.
- **Minimum Requirements**: The arbiter node must still meet **minimum requirements** for etcd to function correctly, especially regarding disk and network speeds.
