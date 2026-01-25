resource "random_password" "keycloak_password" {
  length  = 32
  special = false
}

locals {
  keycloak_username = "admin"
  keycloak_password = random_password.keycloak_password.result

  manifest = <<-YAML
resources:
  requests:
    cpu: ${var.keycloak_cpu}
    memory: ${var.keycloak_memory}
  limits:
    cpu: ${var.keycloak_cpu}
    memory: ${var.keycloak_memory}
service:
  type: ${var.service_type}
livenessProbe:
  httpGet:
    path: /health/live
    port: metrics
  initialDelaySeconds: ${var.liveness_probe_initial_delay}
  failureThreshold: ${var.liveness_probe_failure_threshold}
  periodSeconds: 10
  timeoutSeconds: 5
readinessProbe:
  httpGet:
    path: /health/ready
    port: metrics
  initialDelaySeconds: ${var.readiness_probe_initial_delay}
  failureThreshold: ${var.readiness_probe_failure_threshold}
  periodSeconds: 10
  timeoutSeconds: 5
YAML
}

resource "helm_release" "keycloak" {
  name             = var.helm_release_name
  repository       = "https://charts.pascaliske.dev"
  chart            = "keycloak"
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  set = flatten([
    # Admin credentials (pascaliske chart uses secret.values)
    [
      {
        name  = "secret.values.KEYCLOAK_ADMIN"
        value = local.keycloak_username
      },
      {
        name  = "secret.values.KEYCLOAK_ADMIN_PASSWORD"
        value = local.keycloak_password
      },
    ],
    # extraArgs for Keycloak start command
    var.keycloak_start_optimized ? [
      {
        name  = "extraArgs[0]"
        value = "start"
      },
      {
        name  = "extraArgs[1]"
        value = "--optimized"
      },
      {
        name  = "extraArgs[2]"
        value = "--hostname-strict=false"
      },
      {
        name  = "extraArgs[3]"
        value = "--http-enabled=true"
      },
      ] : [
      {
        name  = "extraArgs[0]"
        value = "start"
      },
      {
        name  = "extraArgs[1]"
        value = "--hostname-strict=false"
      },
      {
        name  = "extraArgs[2]"
        value = "--http-enabled=true"
      },
    ],
    # Environment variables for database configuration
    [
      {
        name  = "env[0].name"
        value = "KC_DB"
      },
      {
        name  = "env[0].value"
        value = "postgres"
      },
      {
        name  = "env[1].name"
        value = "KC_DB_URL"
      },
      {
        name  = "env[1].value"
        value = "jdbc:postgresql://${var.postgresql_host}:${var.postgresql_port}/${var.postgresql_db_name}"
      },
      {
        name  = "env[2].name"
        value = "KC_DB_USERNAME"
      },
      {
        name  = "env[2].value"
        value = var.postgresql_username
      },
      {
        name  = "env[3].name"
        value = "KC_DB_PASSWORD"
      },
      {
        name  = "env[3].value"
        value = var.postgresql_password
      },
    ],
    # Node selector (pascaliske chart uses controller.nodeSelector)
    [
      for key, value in var.node_selector : {
        name  = "controller.nodeSelector.${key}"
        value = value
      }
    ],
    # Tolerations (pascaliske chart uses controller.tolerations)
    [
      for key, value in var.tolerations : {
        name  = "controller.tolerations[${key}].key"
        value = lookup(value, "key", "")
      }
    ],
    [
      for key, value in var.tolerations : {
        name  = "controller.tolerations[${key}].operator"
        value = lookup(value, "operator", "")
      }
    ],
    [
      for key, value in var.tolerations : {
        name  = "controller.tolerations[${key}].value"
        value = lookup(value, "value", "")
      }
    ],
    [
      for key, value in var.tolerations : {
        name  = "controller.tolerations[${key}].effect"
        value = lookup(value, "effect", "")
      }
    ],
  ])

  values = [local.manifest]

  lifecycle {
    ignore_changes = [
      timeout
    ]
  }
}
