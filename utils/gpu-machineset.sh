#!/bin/bash

### Define Instance Types
get_instance_type() {
  case "$1" in
    "Tesla T4 Single GPU") echo "g4dn.4xlarge" ;;
    "Tesla T4 Multi GPU") echo "g4dn.12xlarge" ;;
    "A10G Single GPU") echo "g5.4xlarge" ;;
    "A10G Large GPU") echo "g5.8xlarge" ;;
    "A100") echo "p4d.24xlarge" ;;
    "H100") echo "p5.48xlarge" ;;
    "DL1") echo "dl1.24xlarge" ;;
    "L4 Single GPU") echo "g6.4xlarge" ;;
    "L4 Multi GPU") echo "g6.12xlarge" ;;
    *) echo "Invalid option" ;;
  esac
}

### Prompt User for GPU Instance Type
echo "### Select the GPU instance type:"
PS3='Please enter your choice: '
options=(
  "Tesla T4 Single GPU"
  "Tesla T4 Multi GPU"
  "A10G Single GPU"
  "A10G Large GPU"
  "A100"
  "H100"
  "DL1"
  "L4 Single GPU"
  "L4 Multi GPU"
)
select opt in "${options[@]}"
do
  INSTANCE_TYPE=$(get_instance_type "$opt")
  if [[ -n "$INSTANCE_TYPE" && "$INSTANCE_TYPE" != "Invalid option" ]]; then
    break
  else
    echo "--- Invalid option $REPLY ---"
  fi
done

### Prompt User for Region
read -p "### Enter the AWS region (default: us-west-2): " REGION
REGION=${REGION:-us-west-2}

### Prompt User for Availability Zone
echo "### Select the availability zone (az1, az2, az3):"
PS3='Please enter your choice: '
az_options=("az1" "az2" "az3")
select az_opt in "${az_options[@]}"
do
  case $az_opt in
    "az1") AZ="${REGION}a" ; break ;;
    "az2") AZ="${REGION}b" ; break ;;
    "az3") AZ="${REGION}c" ; break ;;
    *) echo "--- Invalid option $REPLY ---" ;;
  esac
done

# Assign new name for the machineset
NEW_NAME="worker-gpu-$INSTANCE_TYPE-$AZ"

# Check if the machineset already exists
EXISTING_MACHINESET=$(oc get -n openshift-machine-api machinesets -o name | grep "$NEW_NAME")

if [ -n "$EXISTING_MACHINESET" ]; then
  echo "### Machineset $NEW_NAME already exists. Scaling to 1."
  oc scale --replicas=1 -n openshift-machine-api "$EXISTING_MACHINESET"
  echo "--- Machineset $NEW_NAME scaled to 1."
else
  echo "### Creating new machineset $NEW_NAME."
  oc get -n openshift-machine-api machinesets -o name | grep -v ocs | while read -r MACHINESET
  do
    oc get -n openshift-machine-api "$MACHINESET" -o json | jq '
        del(.metadata.uid, .metadata.managedFields, .metadata.selfLink, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.generation, .status) |
        (.metadata.name) |= "'"$NEW_NAME"'" |
        (.spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"]) |= "'"$NEW_NAME"'" |
        (.spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]) |= "'"$NEW_NAME"'" |
        (.spec.template.spec.providerSpec.value.instanceType) |= "'"$INSTANCE_TYPE"'" |
        (.spec.template.spec.metadata.labels["node-role.kubernetes.io/gpu"]) |= "" |
        (.spec.template.spec.metadata.labels["cluster.ocs.openshift.io/openshift-storage"]) |= "" |
        (.spec.template.spec.taints) |= [{ "effect": "NoSchedule", "key": "nvidia.com/gpu" }]' | oc create -f -
    break
  done
  echo "--- New machineset $NEW_NAME created."
fi
