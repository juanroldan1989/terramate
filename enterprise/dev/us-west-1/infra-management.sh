#!/bin/bash

## Usage:
### ./infra-management.sh apply
### ./infra-management.sh destroy

## This script provisions resources for:

## Environment: "dev"
## Region: "us-west-1"

## Set non-interactive mode for Terragrunt
export TG_NON_INTERACTIVE=true

apply () {
  terragrunt run-all apply
}

destroy () {
dirs=(
  "./03-applications/service-a"
  "./02-compute/ecs-clusters/cluster-1"
  "./01-networking/vpc-1"
)

for dir in "${dirs[@]}"; do
  echo "Destroying resources in $dir"
  cd "$dir" || exit 1
  terragrunt destroy --auto-approve
  if [ $? -ne 0 ]; then
    echo "Error destroying resources in $dir"
    exit 1
  fi
  cd - || exit 1
done

echo "All resources destroyed successfully!"
}

if [ "$1" == "apply" ]; then
  apply
elif [ "$1" == "destroy" ]; then
  destroy
else
  echo "Usage: ./infra-management.sh apply"
  echo "Usage: ./infra-management.sh destroy"
fi
