# Migration Guide: v1.x to v2.0

This document explains the breaking changes when upgrading from v1.x to v2.0, which switches from the Bitnami Keycloak chart to the pascaliske/keycloak chart.

## Why the Change?

The previous configuration was designed for the Bitnami Keycloak Helm chart but was incorrectly pointing to the pascaliske/keycloak chart repository. Version 2.0 aligns the module configuration with the actual chart being used.

## Variable Changes

### Removed Variables

| Variable | Reason |
|----------|--------|
| `create_postgresql` | Chart does not include built-in PostgreSQL |
| `storage_class_name` | Not supported by chart |

### New Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `service_type` | string | "ClusterIP" | Kubernetes service type |
| `postgresql_port` | number | 5432 | PostgreSQL database port |

### Changed Variables

| Variable | Change |
|----------|--------|
| `postgresql_host` | Now required (no default) |
| `postgresql_password` | Now required (no default), marked as sensitive |

## Configuration Mapping

### Admin Credentials

```hcl
# v1.x (Bitnami style - not working)
auth.adminUser
auth.adminPassword

# v2.0 (pascaliske style)
secret.values.KEYCLOAK_ADMIN
secret.values.KEYCLOAK_ADMIN_PASSWORD
```

### Database Configuration

```hcl
# v1.x (Bitnami style - not working)
postgresql.enabled
postgresql.auth.database
externalDatabase.host

# v2.0 (environment variables)
env[].name = "KC_DB"
env[].name = "KC_DB_URL"
env[].name = "KC_DB_USERNAME"
env[].name = "KC_DB_PASSWORD"
```

### Node Selector and Tolerations

```hcl
# v1.x
nodeSelector.*
tolerations[*].*

# v2.0
controller.nodeSelector.*
controller.tolerations[*].*
```

## Ingress Configuration

The module now creates a `kubernetes_ingress_v1` resource for AWS ALB ingress controller. The ingress variables remain the same:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_ingress` | bool | true | Whether to create the AWS ALB ingress |
| `ingress_class_name` | string | "alb" | Ingress class name |
| `ingress_group_name` | string | "external" | ALB ingress group name |
| `ingress_hostname` | string | "" | Hostname for the ingress |

The ingress is created as a separate Kubernetes resource (not via Helm values) with the following annotations:

- `alb.ingress.kubernetes.io/target-type: ip`
- `alb.ingress.kubernetes.io/scheme: internet-facing`
- `alb.ingress.kubernetes.io/ssl-redirect: 443`
- `alb.ingress.kubernetes.io/healthcheck-path: /health`

## Migration Steps

1. Update module source to v2.0
2. Remove `create_postgresql` and `storage_class_name` variables
3. Add required `postgresql_host` and `postgresql_password` variables
4. Run `terraform plan` to verify changes
5. Apply changes (this will recreate the Keycloak deployment)
