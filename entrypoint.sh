#!/bin/bash

set -e

TOOL=$1
CONTAINER=$2
COMMAND=$3
DIRECTORY=$4
ACCOUNT=$5
SUFFIX=$6

function terraformPlanRemove() {
    if [[ -z "$SUFFIX" ]]; then
        NAME=$(cat $DIRECTORY/terraform-plan.lock)
        az storage blob delete --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
    else
        SUFFIX_FIXED=$(echo ${SUFFIX} | tr '/' '-')
        NAME=$(cat terraform-plan.lock)-${SUFFIX_FIXED}
        az storage blob delete --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
    fi
}

function terraformPlanUpload() {
    if [[ -z "$SUFFIX" ]]; then
        NAME=${GITHUB_SHA}
    else
        SUFFIX_FIXED=$(echo ${SUFFIX} | tr '/' '-')
        NAME=${GITHUB_SHA}-${SUFFIX_FIXED}
    fi
    az storage blob upload --file $PWD/plan.tfplan --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
}

function terraformPlanDownload() {
    if [[ -z "$SUFFIX" ]]; then
        NAME=$(cat $DIRECTORY/terraform-plan.lock)
        az storage blob download --file $PWD/plan.tfplan --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
    else
        SUFFIX_FIXED=$(echo ${SUFFIX} | tr '/' '-')
        NAME=$(cat terraform-plan.lock)-${SUFFIX_FIXED}
        az storage blob download --file $PWD/plan.tfplan --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
    fi
}

az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
az account set -s $ARM_SUBSCRIPTION_ID

if [[ $COMMAND == "plan" ]]; then
    terraformPlanRemove || true
    if [[ $TOOL == "terraform" ]]; then
        $TOOL init $DIRECTORY
        $TOOL plan -out=$PWD/plan.tfplan $DIRECTORY
    elif [[ $TOOL == "terragrunt" ]]; then
        $TOOL init --terragrunt-working-dir $DIRECTORY
        $TOOL plan -out=$PWD/plan.tfplan --terragrunt-working-dir $DIRECTORY
    fi
    terraformPlanUpload

    if [[ -z "$SUFFIX" ]]; then
        echo "${GITHUB_SHA}" > $DIRECTORY/terraform-plan.lock
        git config --global user.name "${GITHUB_ACTOR}" \
          && git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com" \
          && git add $DIRECTORY/terraform-plan.lock \
          && git commit -m "Update $DIRECTORY/terraform-plan.lock" --allow-empty \
          && git push -u origin HEAD
    fi
fi

if [[ $COMMAND == "apply" ]]; then
    terraformPlanDownload
    if [[ $TOOL == "terraform" ]]; then
        $TOOL init $DIRECTORY
        $TOOL apply $PWD/plan.tfplan
    elif [[ $TOOL == "terragrunt" ]]; then
        $TOOL init --terragrunt-working-dir $DIRECTORY
        $TOOL apply $PWD/plan.tfplan --terragrunt-working-dir $DIRECTORY
    fi
    terraformPlanRemove || true
fi