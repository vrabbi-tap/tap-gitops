#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  set +x
  echo "$0 :: delete IAM Role for Service Account"
  echo "Inputs:"
  echo "- EKS_CLUSTER_NAME -- cluster on which TAP is being installed (and has been configured to be an OIDC Provider"
}

for envvar in EKS_CLUSTER_NAME ; do
  if [[ ! -v ${envvar} ]]; then
    usage
    echo "Expected env var ${envvar} to be set, but was not."
    exit 1
  fi
done

set -x
eksctl delete iamserviceaccount \
  --cluster ${EKS_CLUSTER_NAME} \
  --name tanzu-sync-secrets \
  --namespace tanzu-sync
  
eksctl delete iamserviceaccount \
  --cluster ${EKS_CLUSTER_NAME} \
  --name tap-install-secrets \
  --namespace tap-install
