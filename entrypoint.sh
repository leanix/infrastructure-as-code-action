#!/bin/bash

set -e

TOOL=$1
CONTAINER=$2
COMMAND=$3
DIRECTORY=$4
ACCOUNT=$5

function terraformPlanRemove() {
    NAME=$(cat $DIRECTORY/terraform-plan.lock)
    az storage blob delete --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
}

function terraformPlanUpload() {
    NAME=${GITHUB_SHA}
    az storage blob upload --file $DIRECTORY/plan.tfplan --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
}

function terraformPlanDownload() {
    NAME=$(cat $DIRECTORY/terraform-plan.lock)
    az storage blob download --file $DIRECTORY/plan.tfplan --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
}

az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

if [[ $COMMAND == "plan" ]]; then
    terraformPlanRemove || true
    if [[ $TOOL == "terraform" ]]; then
        $TOOL init $DIRECTORY
        $TOOL plan -out=$DIRECTORY/plan.tfplan $DIRECTORY
    elif [[ $TOOL == "terragrunt" ]]; then
        $TOOL init --terragrunt-working-dir $DIRECTORY
        $TOOL plan -out=$DIRECTORY/plan.tfplan --terragrunt-working-dir $DIRECTORY
    fi
    terraformPlanUpload

    echo "${GITHUB_SHA}" > $DIRECTORY/terraform-plan.lock
    git config --global user.name "${GITHUB_ACTOR}" \
      && git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com" \
      && git add $DIRECTORY/terraform-plan.lock \
      && git commit -m "Update $DIRECTORY/terraform-plan.lock" --allow-empty \
      && git push -u origin HEAD
fi

if [[ $COMMAND == "apply" ]]; then
    terraformPlanDownload
    if [[ $TOOL == "terraform" ]]; then
        $TOOL init $DIRECTORY
        $TOOL apply $DIRECTORY/plan.tfplan
    elif [[ $TOOL == "terragrunt" ]]; then
        $TOOL init --terragrunt-working-dir $DIRECTORY
        $TOOL apply $DIRECTORY/plan.tfplan --terragrunt-working-dir $DIRECTORY
    fi
    terraformPlanRemove || true
fi