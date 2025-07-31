#!/bin/bash
SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/common.sh"

instance_ip=$(cat ${SCRIPT_DIR}/../${SHARED_DIR}/ssh_user)@$(cat ${SCRIPT_DIR}/../${SHARED_DIR}/public_address)

ssh $instance_ip
