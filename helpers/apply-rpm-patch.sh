#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
set -o errexit
set -o pipefail
set -o nounset

# Check if required tools are available
command -v oc >/dev/null 2>&1 || { echo "Error: 'oc' command not found. Please ensure you're logged into an OpenShift cluster." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: 'jq' command not found. Please install jq." >&2; exit 1; }

RPM_FULL_PATH="$1"
PACKAGE=$(basename "$RPM_FULL_PATH")

# Function to show usage
usage() {
    echo "Usage: $0 <rpm-file-path>"
    echo -e "\nThis script installs an RPM package on all OpenShift cluster nodes using rpm-ostree.\n"
    echo "Arguments:"
    echo -e "  rpm-file-path    Path to the RPM file to install\n"
    echo "Example:"
    echo "  $0 /path/to/package.rpm"
    exit 1
}

# Check arguments
if [[ $# -ne 1 ]]; then
    usage
fi

if [[ ! -f "$RPM_FULL_PATH" ]]; then
    echo "Error: RPM file '$RPM_FULL_PATH' not found." >&2
    exit 1
fi

# Get the list of all node IPs
echo "Discovering OpenShift cluster nodes..."
mapfile -t NODE_IPS< <(oc get nodes -o json | jq -r '.items[].status.addresses[0].address')

if [[ ${#NODE_IPS[@]} -eq 0 ]]; then
    echo "Error: No nodes found in the cluster." >&2
    echo "Make sure you're connected to an OpenShift cluster." >&2
    exit 1
fi

echo "Found ${#NODE_IPS[@]} node(s):"
for ip in "${NODE_IPS[@]}"; do
    echo "  - $ip"
done

echo -e "\nInstalling RPM package '$PACKAGE' on ${#NODE_IPS[@]} node(s)...\n"

set -x
for IP in "${NODE_IPS[@]}"; do
    echo "Processing node: $IP"
    scp "$RPM_FULL_PATH" "core@$IP":/var/home/core
    ssh -t "core@$IP" -- sudo rpm-ostree -C override replace /var/home/core/"$PACKAGE"
    sleep 2
done

echo -e "\nRPM installation completed on all nodes."
echo -e "\nIMPORTANT: The nodes need to be rebooted to apply the rpm-ostree changes."
echo "Plan the reboots carefully to maintain cluster availability:"
echo "- Reboot nodes one at a time"
echo "- Wait for etcd to be healthy on each node before rebooting the next"
echo "- Monitor cluster health during the process"
echo -e "\nAfter rebooting each node, verify etcd health with:"
echo "  ssh core@<NODE_IP> podman exec etcd etcdctl member list"
echo -e "\nWait for the command to succeed before proceeding to reboot the next node."

