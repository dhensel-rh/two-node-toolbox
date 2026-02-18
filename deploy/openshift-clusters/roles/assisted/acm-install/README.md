# acm-install Role

Installs ACM or MCE operator on a hub cluster and configures the assisted installer service for spoke TNF cluster deployment.

## Description

This role prepares an existing hub OpenShift cluster to deploy spoke TNF clusters via the assisted installer. It:

1. Validates hub cluster health and prerequisites
2. Provisions hostPath storage for the assisted service
3. Installs the ACM or MCE operator (auto-detects channel)
4. Creates the AgentServiceConfig with RHCOS ISO auto-extracted from the hub release image
5. Enables TNF cluster support in the assisted service
6. Configures BMO to watch all namespaces and disables the provisioning network

## Requirements

- A running hub OpenShift cluster (deployed via `make deploy fencing-ipi` or equivalent)
- Hub kubeconfig accessible at `~/auth/kubeconfig`
- Pull secret with access to required registries
- `oc` CLI available on the hypervisor

## Role Variables

### Configurable Variables (defaults/main.yml)

- `hub_operator`: Operator to install - `"acm"` or `"mce"` (default: `"acm"`)
- `acm_channel`: ACM operator channel - `"auto"` detects from packagemanifest (default: `"auto"`)
- `mce_channel`: MCE operator channel (default: `"auto"`)
- `assisted_storage_method`: Storage backend - currently only `"hostpath"` (default: `"hostpath"`)
- `assisted_images_path`: Host directory for ISO images (default: `/var/lib/assisted-images`)
- `assisted_db_path`: Host directory for database (default: `/var/lib/assisted-db`)
- `assisted_images_size`: PV size for images (default: `50Gi`)
- `assisted_db_size`: PV size for database (default: `10Gi`)
- `assisted_storage_class`: StorageClass name (default: `assisted-service`)

### Timeout Variables

- `acm_csv_timeout`: Operator CSV install timeout in seconds (default: `900`)
- `multiclusterhub_timeout`: MultiClusterHub readiness timeout (default: `1800`)
- `assisted_service_timeout`: Assisted service pod readiness timeout (default: `600`)
- `metal3_stabilize_timeout`: Metal3 pod stabilization timeout after provisioning changes (default: `300`)

### Variables Set by Playbook

These are set in `assisted-install.yml` and passed to the role:

- `hub_kubeconfig`: Path to hub cluster kubeconfig
- `pull_secret_path`: Path to pull secret on the hypervisor
- `hub_release_image`: Hub cluster release image (extracted in playbook pre_tasks)
- `hub_ocp_version`: Hub OCP version major.minor (extracted in playbook pre_tasks)
- `effective_release_image`: Release image to use for the spoke (hub image or user override)

## Task Flow

1. **validate.yml** - Checks hub cluster health, node readiness, and API access
2. **storage.yml** - Creates hostPath PVs, StorageClass, and fixes permissions/SELinux on hub nodes
3. **install-operator.yml** - Installs ACM/MCE operator subscription, waits for CSV, creates MultiClusterHub
4. **agent-service-config.yml** - Extracts RHCOS ISO URL from release image, creates AgentServiceConfig
5. **enable-tnf.yml** - Enables TNF support in assisted service configuration
6. **enable-watch-all-namespaces.yml** - Patches Provisioning CR to enable BMO in all namespaces

## Usage

This role is not called directly. It is invoked via `assisted-install.yml`:

```bash
make deploy fencing-assisted
# or
ansible-playbook assisted-install.yml -i inventory.ini
```

## Troubleshooting

- Check operator CSV status: `oc get csv -n open-cluster-management`
- Check MultiClusterHub status: `oc get multiclusterhub -n open-cluster-management`
- Check assisted service pods: `oc get pods -n multicluster-engine -l app=assisted-service`
- Check AgentServiceConfig: `oc get agentserviceconfig agent -o yaml`
- Check events: `oc get events -n multicluster-engine --sort-by='.lastTimestamp'`