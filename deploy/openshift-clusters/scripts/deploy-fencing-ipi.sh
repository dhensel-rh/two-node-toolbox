#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$0")
# Get the deploy directory (two levels up from scripts)
DEPLOY_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

set -o nounset
set -o errexit
set -o pipefail

# Check if instance data exists
if [[ ! -f "${DEPLOY_DIR}/aws-hypervisor/instance-data/aws-instance-id" ]]; then
    echo "Error: No instance found. Please run 'make deploy' first."
    exit 1
fi

echo "Deploying fencing IPI cluster..."

# Check if inventory.ini exists in the openshift-clusters directory
if [[ ! -f "${DEPLOY_DIR}/openshift-clusters/inventory.ini" ]]; then
    echo "Error: inventory.ini not found in ${DEPLOY_DIR}/openshift-clusters/"
    echo "Please ensure the inventory file is properly configured."
    echo "You can run 'make inventory' to update it with current instance information."
    exit 1
fi

# Navigate to the openshift-clusters directory and run the setup playbook
echo "Running Ansible setup playbook with fencing topology in non-interactive mode..."
cd "${DEPLOY_DIR}/openshift-clusters"

# Run the setup playbook with fencing topology and non-interactive mode
ansible-playbook setup.yml \
    -e "topology=fencing" \
    -e "interactive_mode=false" \
    -i inventory.ini

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✓ OpenShift fencing cluster deployment completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Source the proxy environment from anywhere:"
    echo "   source ${DEPLOY_DIR}/openshift-clusters/proxy.env"
    echo "   (or from openshift-clusters directory: source proxy.env)"
    echo "2. Verify cluster access: oc get nodes"
    echo "3. Access the cluster console if needed"
else
    echo "Error: OpenShift cluster deployment failed!"
    echo "Check the Ansible logs for more details."
    exit 1
fi 