# Redfish Role

This role configures PCS (Pacemaker/Corosync) Stonith resources for Bare Metal Hosts using Redfish fencing.

## Description

The redfish role automates the configuration of STONITH (Shoot-The-Other-Node-In-The-Head) resources for OpenShift bare metal nodes using Redfish BMC interfaces. This role runs on localhost and uses your local kubeconfig to access the OpenShift cluster. It:

1. Discovers all BareMetalHost (BMH) resources in the specified namespace
2. Extracts BMC credentials and connection details from each BMH
3. Uses `oc debug` commands to access cluster nodes (no SSH required)
4. Configures PCS stonith resources on each node using `fence_redfish`
5. Enables stonith in the cluster

## Requirements

- OpenShift cluster with bare metal nodes
- BMH resources configured with Redfish BMC details
- `kubernetes.core` Ansible collection
- `oc` CLI tool available in PATH
- Valid kubeconfig file with cluster-admin or equivalent permissions
- Appropriate permissions to run `oc debug` commands on cluster nodes

**Note**: This role runs on localhost (the machine where you execute the playbook) and uses your local kubeconfig to access the OpenShift cluster. It does not require SSH access to the cluster nodes.

## Dependencies

- kubernetes.core collection: `ansible-galaxy collection install kubernetes.core`

## Role Variables

### Default Variables (defaults/main.yml)

- `bmh_namespace`: Namespace where BareMetalHost resources are deployed (default: "openshift-machine-api")
- `ssl_insecure_param`: SSL certificate verification parameter (default: "")

## Usage

### Running the Role

This role is designed to run on localhost (your local machine) and uses your local kubeconfig to access the OpenShift cluster. Ensure you have a valid kubeconfig and are authenticated to the cluster before running.

```bash
# Ensure you're authenticated to your OpenShift cluster
oc whoami
```
If you deployed the cluster using the procedure in [openshift-clusters](../../README.md), you should have sourced the `proxy.env` file to have a valid connection. 

Use the top-level `redfish.yml` playbook:


```bash
# Run the playbook (executes on localhost, accesses cluster via kubeconfig)
ansible-playbook redfish.yml
```

### Custom Variables

To override default variables, create a vars file or use `-e` option:

```bash
ansible-playbook redfish.yml -e bmh_namespace=custom-namespace
```

## Verification

After the Redfish configuration is complete, you can verify the stonith setup using these commands:

```bash
oc debug node/master-0 -- chroot /host sudo pcs property config
```

Sample output:
```
Starting pod/master-0-debug-wzsz9 ...
To use host binaries, run `chroot /host`
Cluster Properties: cib-bootstrap-options
  cluster-infrastructure=corosync
  cluster-name=TNF
  dc-version=2.1.9-1.el9-49aab9983
  have-watchdog=false
  stonith-enabled=true

Removing debug pod ...
```

```bash
oc debug node/master-0 -- chroot /host sudo pcs status
```

Sample output:
```
Starting pod/master-0-debug-hlh52 ...
To use host binaries, run `chroot /host`
Cluster name: TNF
Cluster Summary:
  * Stack: corosync (Pacemaker is running)
  * Current DC: master-0 (version 2.1.9-1.el9-49aab9983) - partition with quorum
  * Last updated: Mon Jul  7 23:05:29 2025 on master-0
  * Last change:  Mon Jul  7 23:05:24 2025 by root via root on master-1
  * 2 nodes configured
  * 6 resource instances configured

Node List:
  * Online: [ master-0 master-1 ]

Full List of Resources:
  * Clone Set: kubelet-clone [kubelet]:
    * Started: [ master-0 master-1 ]
  * Clone Set: etcd-clone [etcd]:
    * Started: [ master-0 master-1 ]
  * master-0_redfish	(stonith:fence_redfish):	 Started master-0
  * master-1_redfish	(stonith:fence_redfish):	 Started master-1

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled

Removing debug pod ...
```

## Notes

- **Localhost Execution**: This role runs entirely on localhost (your local machine) and uses your local kubeconfig to access the OpenShift cluster
- **No SSH Required**: Uses OCP debug commands instead of SSH, making it work out of the box on any OpenShift cluster without requiring SSH keys or network access to individual nodes
- **Kubeconfig Dependency**: Requires a valid kubeconfig file with appropriate permissions to access BMH resources and run debug commands on cluster nodes
- **Automatic Processing**: The role processes all BMH resources found in the namespace automatically
- **SSL Configuration**: SSL certificate verification can be disabled by setting appropriate BMH configuration
- **Security**: All sensitive operations are performed with appropriate security considerations 