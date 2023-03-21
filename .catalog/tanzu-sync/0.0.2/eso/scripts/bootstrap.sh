#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  set +x
  echo "Inputs:"
  echo "- INSTALL_REGISTRY_HOSTNAME -- hostname of OCI Registry containing TAP packages"
  echo "- INSTALL_REGISTRY_USERNAME -- username of account to OCI Registry containing TAP packages"
  echo "- INSTALL_REGISTRY_PASSWORD -- password of account to OCI Registry containing TAP packages"
  echo "- KAPP_KUBECONFIG_CONTEXT -- kubectl context name for the target cluster"
  echo ""
}

for envvar in INSTALL_REGISTRY_USERNAME INSTALL_REGISTRY_PASSWORD INSTALL_REGISTRY_HOSTNAME KAPP_KUBECONFIG_CONTEXT ; do
  if [[ ! -v ${envvar} ]]; then
    usage
    echo "Expected env var ${envvar} to be set, but was not."
    exit 1
  fi
done

kubectl --context="${KAPP_KUBECONFIG_CONTEXT}"  \
  apply \
  -f <(ytt -f tanzu-sync/bootstrap/ \
           -v registry.hostname="${INSTALL_REGISTRY_HOSTNAME}" \
           -v registry.username="${INSTALL_REGISTRY_USERNAME}" \
           -v registry.password="${INSTALL_REGISTRY_PASSWORD}" \
      ) $@
           
echo ""
echo "Next steps:"
echo ""
echo "$  ./tanzu-sync/scripts/configure.sh"
echo ""
