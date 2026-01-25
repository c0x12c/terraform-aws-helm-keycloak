# EKS-Helm/Keycloak

This module helps install and configure Keycloak for EKS cluster via Helm chart.

## Usage

### Install Keycloak

```hcl
module "eks_helm_keycloak" {
  source  = "c0x12c/helm-keycloak/aws"
  version = "~> 1.1.0"

  create_postgresql   = false
  postgresql_host     = "db_host"
  postgresql_db_name  = "db_name"
  postgresql_username = "db_username"
  postgresql_password = "db_password"

  create_ingress     = true
  ingress_class_name = "alb"
  ingress_hostname   = "keycloak.example.com"

  node_selector = {}
  tolerations = []
}

```

## Examples

- [Example](./examples/complete)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.8 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.keycloak](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.keycloak](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [random_password.keycloak_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_ingress"></a> [create\_ingress](#input\_create\_ingress) | Whether to create the AWS ALB ingress | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Determines whether a new namespace should be created. Set to 'true' to create the namespace; otherwise, set to 'false' to use an existing namespace. | `bool` | `true` | no |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | The chart version of keycloak | `string` | `"0.2.0"` | no |
| <a name="input_helm_release_name"></a> [helm\_release\_name](#input\_helm\_release\_name) | The Helm release of the services. | `string` | `"keycloak"` | no |
| <a name="input_ingress_class_name"></a> [ingress\_class\_name](#input\_ingress\_class\_name) | Ingress class name | `string` | `"alb"` | no |
| <a name="input_ingress_group_name"></a> [ingress\_group\_name](#input\_ingress\_group\_name) | ALB ingress group name | `string` | `"external"` | no |
| <a name="input_ingress_hostname"></a> [ingress\_hostname](#input\_ingress\_hostname) | Hostname for the ingress | `string` | `""` | no |
| <a name="input_keycloak_cpu"></a> [keycloak\_cpu](#input\_keycloak\_cpu) | Keycloak cpu | `string` | `"450m"` | no |
| <a name="input_keycloak_memory"></a> [keycloak\_memory](#input\_keycloak\_memory) | Keycloak memory | `string` | `"1024Mi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Namespace of the services. | `string` | `"keycloak"` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for the keycloak | `map(string)` | `{}` | no |
| <a name="input_postgresql_db_name"></a> [postgresql\_db\_name](#input\_postgresql\_db\_name) | Name of the database | `string` | `"keycloak"` | no |
| <a name="input_postgresql_host"></a> [postgresql\_host](#input\_postgresql\_host) | Host for the PostgreSQL database | `string` | n/a | yes |
| <a name="input_postgresql_password"></a> [postgresql\_password](#input\_postgresql\_password) | Password for the database | `string` | n/a | yes |
| <a name="input_postgresql_port"></a> [postgresql\_port](#input\_postgresql\_port) | Port for the PostgreSQL database | `number` | `5432` | no |
| <a name="input_postgresql_username"></a> [postgresql\_username](#input\_postgresql\_username) | Username for the database | `string` | `"keycloak"` | no |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Kubernetes service type | `string` | `"ClusterIP"` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | Tolerations for the keycloak | <pre>list(object({<br/>    key      = string<br/>    operator = string<br/>    value    = optional(string)<br/>    effect   = optional(string)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_keycloak_password"></a> [keycloak\_password](#output\_keycloak\_password) | n/a |
| <a name="output_keycloak_username"></a> [keycloak\_username](#output\_keycloak\_username) | n/a |
<!-- END_TF_DOCS -->
