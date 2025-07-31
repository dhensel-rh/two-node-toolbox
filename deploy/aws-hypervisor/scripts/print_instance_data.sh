#!/bin/bash
SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/common.sh"

echo "Stack: $(cat ${SCRIPT_DIR}/../${SHARED_DIR}/rhel_host_stack_name)"
echo "Host: $(cat ${SCRIPT_DIR}/../${SHARED_DIR}/public_address)"
echo "User: $(cat ${SCRIPT_DIR}/../${SHARED_DIR}/ssh_user)"
echo "Cockpit URL: http://$(cat ${SCRIPT_DIR}/../${SHARED_DIR}/public_address):9090"
