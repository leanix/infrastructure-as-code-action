# LeanIX Infrastructure as Code Action

The LeanIX Infrastructure as Code Action automates the rollout of given terraform/terragrunt projects.

## Prerequisites

The action requires that the following environment variables are present in the workflow.

- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_TENANT_ID

Both `ARM_CLIENT_ID` and `ARM_CLIENT_SECRET` are the Azure Service Principal credentials.

- ARM_TENANT_ID

The `ARM_TENANT_ID` (Azure AD tenant id) can be retrieved by calling `az account show | jq .tenantId`.

For storing the Terraform plan file the action uses an Azure Storage account.

## Use Action

### Terraform `plan`

```yaml
- name: Terraform plan
  uses: leanix/infrastructure-as-code-action@master
  with:
    tool: 'terraform'
    blobaction: 'upload'
    container: 'mycontainer'
    command: 'plan'
    account: 'myAzureStorageAccount'
```

### Terraform `apply`

```yaml
- name: Terraform apply
  uses: leanix/infrastructure-as-code-action@master
  with:
    tool: 'terraform'
    blobaction: 'download'
    container: 'mycontainer'
    command: 'apply'
    account: 'myAzureStorageAccount'
```

## Copyright and license

Copyright 2020 LeanIX GmbH under the [Unlicense license](LICENSE).
