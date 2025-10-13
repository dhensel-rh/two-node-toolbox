# Helpers

Utilities for OpenShift cluster operations including package management and cluster validation.

## Description

This directory contains multiple helper scripts for various OpenShift cluster operations:

- **Resource Agent Patching**: Scripts and playbooks for installing RPM packages on cluster nodes using rpm-ostree's override functionality
- **Fencing Validation**: Tools for validating two-node cluster fencing configuration and health

## Requirements

### For resource-agents-patch.sh
- `oc` CLI tool (logged into OpenShift cluster)
- `jq` for JSON processing
- SSH access to cluster nodes

### For resource-agents-patch.yml
- Ansible
- Inventory file containing OpenShift cluster nodes (separate from hypervisor deployment inventory, see `inventory_ocp_hosts.sample`)
- SSH access configured for `core` user

## Available Scripts

### fencing_validator.sh

Validates fencing configuration and health for two-node OpenShift clusters with STONITH-enabled Pacemaker.

**Features:**
- Non-disruptive validation (default): Checks STONITH presence/enabled status, node health, etcd quorum, and daemon status
- Disruptive testing: Performs actual fencing of both nodes to verify recovery (optional with `--disruptive`)
- Multiple transport methods: Auto-detection, SSH, or oc debug
- IPv4/IPv6 support with automatic node discovery

**Requirements:**
- `oc` CLI tool (logged into OpenShift cluster) 
- For SSH transport: passwordless sudo access to cluster nodes
- Two-node cluster with fencing topology

**Usage:**

*From outside the hypervisor (uses oc debug transport by default):*
```bash
# Non-disruptive validation (recommended)
./fencing_validator.sh

# With custom hosts
./fencing_validator.sh --hosts "10.0.0.10,10.0.0.11"
```

*From inside the hypervisor via ansible (requires hypervisor deployed via `make deploy`):*
```bash
# Copy script to hypervisor and execute remotely
ansible all -i deploy/openshift-clusters/inventory.ini -m copy -a "src=helpers/fencing_validator.sh dest=~/fencing_validator.sh mode=0755"
ansible all -i deploy/openshift-clusters/inventory.ini -m shell -a "./fencing_validator.sh"
```

*Disruptive testing options:*
```bash
# Disruptive testing (NOTE: Not yet supported - under development)
./fencing_validator.sh --disruptive

# Dry run to see what would be tested
./fencing_validator.sh --disruptive --dry-run
```

**Note:** Disruptive testing functionality is not yet fully supported and should not be used in production environments.

### resource-agents-patch.sh

Patches OpenShift cluster nodes with RPM packages using rpm-ostree override functionality.

```bash
./resource-agents-patch.sh /path/to/package.rpm
```

**Process:**
1. Validates required tools and RPM file
2. Discovers all node IPs via OpenShift API
3. Copies RPM to each node using SCP
4. Installs package with `rpm-ostree override replace`
5. Provides manual reboot commands

### Ansible Playbook

```bash
ansible-playbook -i inventory_ocp_hosts resource-agents-patch.yml -e rpm_full_path=/path/to/package.rpm
```

**Note**: The inventory file should list the OpenShift cluster nodes (VMs), not the hypervisor host. Copy `inventory_ocp_hosts.sample` to `inventory_ocp_hosts` and update with your cluster node IPs.

**Process:**
1. Validates RPM file existence
2. Copies RPM to all nodes
3. Installs using rpm-ostree override
4. Reboots nodes one at a time
5. Verifies etcd health after reboot

## Notes

- Both tools use `rpm-ostree override replace` which is appropriate for updating existing packages
- Node reboots are required to activate rpm-ostree changes
- The Ansible playbook handles rebooting automatically; the shell script requires manual intervention
- Plan reboots carefully to maintain cluster availability
- Monitor cluster health during the patching process 