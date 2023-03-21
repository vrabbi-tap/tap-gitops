## Tanzu Sync (w/ External Secrets Operator)

### Pre-Requisites

- AWS CLI : https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- EKS CLI : https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html
- an EKS cluster

### Pre-Installation

0. Verify the current terminal session is properly authenticated and targeting the correct cluster
   ```console
   $ aws sts get-caller-identity
   {
       "UserId": "...",
       "Account": "...",
       "Arn": "..."
   }

   $ eksctl get cluster
   NAME     REGION    EKSCTL CREATED
   ...      ...       ...
   ```

1. In AWS Secrets Manager, save credentials for Tanzu Sync:
   1. create a secret containing the SSH private key that has access to this git repo and associated known hosts:
      ```json
      {
        "ssh-privatekey": "-----BEGIN OPENSSH PRIVATE KEY-----\nb3B................................................................tZW\nQyN................................................................6XZ\nMQA................................................................x+w\nAAA................................................................0pR\na6I..........................xQF\n-----END OPENSSH PRIVATE KEY-----\n",
        "ssh-knownhosts": "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
      }
      ```
      - By default, this secret's name must be: `dev/${EKS_CLUSTER_NAME}/tanzu-sync/sync-git-ssh`.
      - If this secret is given a different name, it must also be changed:
        - in the IAM Policy governing access to secrets needed for Tanzu Sync, by setting
          `ASM_RESOURCE_ID_FOR_TANZU_SYNC` before running `create-policies.sh`, below.
        - in the Tanzu Sync data value `secrets.eso.remote_refs.sync_git_ssh.ssh_private_key`.
          This is typically set in `tanzu-sync/app/values/tanzu-sync-eso.yaml`
          (a file created by running `configure.sh`).

   2. create a secret containing the credentials for the OCI registry hosting TAP software:
      ```json
      {
        "auths": {
          "registry.tanzu.vmware.com": {
            "username": "YOUR-USERNAME@example.vmware.com",
            "password": "YOURpasswordHERE"
          }
        }
      }
      ```
      - Using the defaults, this secret's name is: `dev/${EKS_CLUSTER_NAME}/tanzu-sync/install-registry-dockerconfig`.
      - If this secret is given a different name, it will also need to be changed:
        - in the IAM Policy governing access to secrets needed for Tanzu Sync, by setting
          `ASM_RESOURCE_ID_FOR_TANZU_SYNC` before running `create-policies.sh`, below.
        - in the Tanzu Sync data value `secrets.eso.remote_refs.install_registry_dockerconfig.dockerconfigjson`.
          This is typically set in `tanzu-sync/app/values/tanzu-sync-eso.yaml`
          (created by running `configure.sh`).

2. In AWS Secrets Manager, save the "sensitive values" for Tanzu Application Platform :
   1. create a secret which will contain _all_ sensitive values for the TAP install. \
      At a minimum this would be credentials to an OCI registry with read/write perms for `shared.image_registry`.
      Example: using GCR as build registry:
       ```
       shared:
         image_registry:
           project_path: "gcr.io/cf-k8s-lifecycle-tooling-klt/ryanjo/tap"
           username: "_json_key"
           password: |
             { ... put actual service account JSON, here ... }
       ```
      - Using the defaults, this secret's name is: `dev/${EKS_CLUSTER_NAME}/tap/sensitive-values.yaml`.
      - If this secret is given a different name, it will also need to be changed:
        - in the IAM Policy governing access to secrets needed for Tanzu Sync, by setting
          `ASM_RESOURCE_ID_FOR_TAP` before running `create-policies.sh`, below.
        - in the TAP install data value
          `tap_install.secrets.eso.remote_refs.tap_sensitive_values.sensitive_tap_values_yaml`.
          This is typically set in `cluster-config/values/tap-install-eso-values.yaml`
          (created by running `configure.sh`).

3. In AWS Identity and Access Manager (IAM), create two IAM Policies that will grant read access to secrets
   for your cluster: one for Tanzu Sync secrets; the other TAP install values:
   ```console
   $ export EKS_CLUSTER_NAME=(your-EKS-cluster-name)
   $ ./tanzu-sync/scripts/aws/create-policies.sh
   ```
   where:
   - `EKS_CLUSTER_NAME` is the name as it appears in `eksctl get clusters`
   - If secret names were changed from the default, above, the corresponding resource ID must be set for
     `ASM_RESOURCE_ID_FOR_TANZU_SYNC` and/or `ASM_RESOURCE_ID_FOR_TAP` (inspect the script for use).

4. Create a paired set of IAM Role and Service Account for your cluster. This will create a Kubernetes Service Account
   that will be authorized to assume the IAM Role which has been granted the policy we created in the previous step:
   ```console
   $ ./tanzu-sync/scripts/aws/create-irsa.sh
   ```

#### Bootstrap Installation

1. In your cluster, apply the bootstrapping:
   ```console
   $ export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
   $ export INSTALL_REGISTRY_USERNAME=YOUR-USERNAME@example.vmware.com
   $ export INSTALL_REGISTRY_PASSWORD="YOURpasswordHERE"
   $ export KAPP_KUBECONFIG_CONTEXT="(kubeconfig context name for this cluster)"
   $ ./tanzu-sync/scripts/bootstrap.sh
   ```

Next: go to README.md's "Install Tanzu Sync" section.
