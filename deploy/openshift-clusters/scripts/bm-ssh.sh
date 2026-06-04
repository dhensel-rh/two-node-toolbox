#!/bin/bash
#
# SSH to a bare metal host initialized with bm-init.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

set -o nounset
set -o errexit
set -o pipefail

MARKER_FILE="${DEPLOY_DIR}/aws-hypervisor/instance-data/bare-metal-host"

if [[ ! -f "${MARKER_FILE}" ]]; then
    echo "Error: No bare metal host found. Run 'make bm-init' first."
    exit 1
fi

HOST_TARGET=$(cat "${MARKER_FILE}")
echo "Connecting to bare metal host: ${HOST_TARGET}"
ssh "${HOST_TARGET}"
