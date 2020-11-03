#!/bin/bash

set -e

ENTRYPOINT=$1
BLOBACTION=$2
CONTAINER=$3
COMMAND=$4
DIRECTORY=$5
ACCOUNT=$6

function terraformPlanRemove() {
    NAME=$(cat $DIRECTORY/terraform-plan.lock)
    az storage blob delete --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
}

function terraformPlanUpload() {
    NAME=${{ github.sha }}
    az storage blob $BLOBACTION --file $DIRECTORY/plan.tfplan --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
}

function terraformPlanDownload() {
    NAME=$(cat $DIRECTORY/terraform-plan.lock)
    az storage blob $BLOBACTION --file $DIRECTORY/plan.tfplan --container $CONTAINER --name $NAME --auth-mode key --account-name $ACCOUNT
}

az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

if [[ $COMMAND == "plan" ]]; then
    terraformPlanRemove
    $ENTRYPOINT init $DIRECTORY
    $ENTRYPOINT plan -out=$DIRECTORY/plan.tfplan $DIRECTORY
    terraformPlanUpload

    echo ${{ github.sha }} > $DIRECTORY/terraform-plan.lock
    git config --global user.name "${{ github.actor }}" \
      && git config --global user.email "${{ github.actor }}@users.noreply.github.com" \
      && git add $DIRECTORY/terraform-plan.lock \
      && git commit -m "Update $DIRECTORY/terraform-plan.lock" --allow-empty \
      && git push -u origin HEAD
fi

if [[ $COMMAND == "apply" ]]; then
    terraformPlanDownload
    $ENTRYPOINT init $DIRECTORY
    $ENTRYPOINT apply $DIRECTORY/plan.tfplan $DIRECTORY
    terraformPlanRemove
fi