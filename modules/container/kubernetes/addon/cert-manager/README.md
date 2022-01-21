# Terraform Module: kubernetes/addon/cert-manager 

Installs the `Kubernetes cert-manager` addon on a given AKS cluster.

@see: [Kubernetes cert-manager](https://cert-manager.io/docs/)

## Prerequisites

## Input Variables

| Name | Type | Description | Default | Example |
| --- | --- | --- | --- | --- | 
| region_name | string | Name of an Azure region that hosts this solution (like West Europe) | | |
| region_code | string | Code of an Azure region that hosts this solution (like westeu for West Europe) | | |
| solution_name | string | Name of this Azure solution | | |
| solution_stage | string | Stage of this Azure solution (like E, K, P) | | |
| solution_fqn | string | Fully qualified name of this Azure solution | | |
| resource_group_name | string | The name of the resource group supposed to own all allocated resources | | |
| resource_group_location | string | The location of the resource group supposed to own all allocated resources | | |
| common_tags | map(string) | Map of common tags to be attached to all managed Azure resources
| addon_enabled | bool | controls if this addon will be installed on the target AKS cluster | true | |

## Output Values

| Name | Type | Description |
| --- | --- | --- | 

## TODO's
