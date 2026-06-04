#!/bin/bash
#
# Shared helper functions for cluster management scripts.
# Supports both AWS EC2 and bare metal deployments.
#

# Detect the instance type (aws or baremetal) by checking for marker files.
# Prints the type to stdout and returns 0, or prints an error and returns 1.
check_instance() {
    local deploy_dir="$1"

    if [[ -f "${deploy_dir}/aws-hypervisor/instance-data/aws-instance-id" ]]; then
        echo "aws"
        return 0
    elif [[ -f "${deploy_dir}/aws-hypervisor/instance-data/bare-metal-host" ]]; then
        echo "baremetal"
        return 0
    fi

    echo "Error: No instance found. Run 'make deploy' (EC2) or 'make bm-init' (bare metal) first." >&2
    return 1
}

# Get a display identifier for the current instance (instance ID or hostname).
get_instance_display() {
    local deploy_dir="$1"
    local instance_type="$2"

    case "${instance_type}" in
        aws)
            cat "${deploy_dir}/aws-hypervisor/instance-data/aws-instance-id"
            ;;
        baremetal)
            cat "${deploy_dir}/aws-hypervisor/instance-data/bare-metal-host"
            ;;
    esac
}

# Get the SSH user and host for connecting to the hypervisor.
get_ssh_target() {
    local deploy_dir="$1"
    local instance_type="$2"

    case "${instance_type}" in
        aws)
            local ssh_user host_ip
            ssh_user=$(cat "${deploy_dir}/aws-hypervisor/instance-data/ssh_user")
            host_ip=$(cat "${deploy_dir}/aws-hypervisor/instance-data/public_address")
            echo "${ssh_user}@${host_ip}"
            ;;
        baremetal)
            # Read the first metal_machine host from the inventory
            grep -A1 '^\[metal_machine\]' "${deploy_dir}/openshift-clusters/inventory.ini" \
                | tail -1 | awk '{print $1}'
            ;;
    esac
}
