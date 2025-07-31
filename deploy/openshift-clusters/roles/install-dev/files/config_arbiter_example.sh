#!/bin/bash

export IP_STACK="v4"
export NUM_WORKERS=0
export ENABLE_ARBITER="true"
export ARBITER_MEMORY=16384
export MASTER_MEMORY=32768
export MASTER_DISK=100
export NUM_MASTERS=2
export FEATURE_SET="TechPreviewNoUpgrade"

# If you want to avoid using the CI_TOKEN, uncomment this variable, but it has side effects.
# You can read more on this here: https://github.com/openshift-metal3/dev-scripts/blob/3f070cfd36977381a186cadfb44887856d652bed/config_example.sh#L21
# export OPENSHIFT_CI="true"



# You can find the latest public images in https://quay.io/repository/openshift-release-dev/ocp-release?tab=tags 
# and select your preferred version. Public sources can be found at https://mirror.openshift.com/pub/openshift-v4/

export OPENSHIFT_RELEASE_IMAGE=quay.io/openshift-release-dev/ocp-release:4.19.0-rc.5-multi-x86_64 
# Unless you need to override the installer image, this is not needed
# export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=""