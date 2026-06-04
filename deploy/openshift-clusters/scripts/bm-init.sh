#!/bin/bash
#
# Initialize a bare metal host for two-node cluster deployment.
# Usage: bm-init.sh [user@host]
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

set -o nounset
set -o errexit
set -o pipefail

INSTANCE_DATA_DIR="${DEPLOY_DIR}/aws-hypervisor/instance-data"
INVENTORY_FILE="${DEPLOY_DIR}/openshift-clusters/inventory.ini"

HOST_TARGET="${1:-}"

if [[ -z "${HOST_TARGET}" ]]; then
    read -rp "Enter bare metal host (user@host or IP): " HOST_TARGET
fi

if [[ -z "${HOST_TARGET}" ]]; then
    echo "Error: No host specified."
    exit 1
fi

# If only an IP/hostname was given, default to root@
if [[ "${HOST_TARGET}" != *@* ]]; then
    HOST_TARGET="root@${HOST_TARGET}"
fi

echo "Initializing bare metal host: ${HOST_TARGET}"

# Generate inventory file
echo "Generating inventory.ini..."
cat > "${INVENTORY_FILE}" <<EOF
[metal_machine]
${HOST_TARGET} ansible_ssh_extra_args='-o ServerAliveInterval=30 -o ServerAliveCountMax=120'

[metal_machine:vars]
ansible_become_password=""
EOF

# Run the init-host playbook
echo "Running init-host.yml playbook..."
cd "${DEPLOY_DIR}/openshift-clusters"

if ansible-playbook init-host.yml -i inventory.ini; then
    echo ""
    echo "Host initialization completed successfully!"

    # Write the bare metal marker file
    mkdir -p "${INSTANCE_DATA_DIR}"
    echo "${HOST_TARGET}" > "${INSTANCE_DATA_DIR}/bare-metal-host"

    echo ""
    echo "Next steps:"
    echo "  Deploy a cluster:"
    echo "    make bm-fencing-agent"
    echo "    make bm-arbiter-agent"
else
    echo "Error: Host initialization failed!"
    echo "Check the Ansible logs for more details."
    exit 1
fi
