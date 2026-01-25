resource "random_password" "keycloak_password" {
  length  = 32
  special = false
}

resource "random_password" "postgresql_password" {
  count   = var.create_postgresql == true ? 1 : 0
  length  = 32
  special = false
}

locals {
  keycloak_username   = "admin"
  keycloak_password   = random_password.keycloak_password.result
  postgresql_password = var.create_postgresql == true ? random_password.postgresql_password[0].result : var.postgresql_password

  # Database configuration for keycloakx chart
  database_set_values = var.create_postgresql ? [
    { name = "dbchecker.enabled", value = "true" },
    { name = "database.vendor", value = "postgres" },
    { name = "database.hostname", value = "${var.helm_release_name}-postgresql" },
    { name = "database.port", value = "5432" },
    { name = "database.database", value = var.postgresql_db_name },
    { name = "database.username", value = var.postgresql_username },
    { name = "database.password", value = local.postgresql_password },
    { name = "postgresql.enabled", value = "true" },
    { name = "postgresql.auth.database", value = var.postgresql_db_name },
    { name = "postgresql.auth.username", value = var.postgresql_username },
    { name = "postgresql.auth.password", value = local.postgresql_password },
    { name = "postgresql.auth.postgresPassword", value = local.postgresql_password },
    ] : [
    { name = "dbchecker.enabled", value = "true" },
    { name = "database.vendor", value = "postgres" },
    { name = "database.hostname", value = var.postgresql_host },
    { name = "database.port", value = tostring(var.postgresql_port) },
    { name = "database.database", value = var.postgresql_db_name },
    { name = "database.username", value = var.postgresql_username },
    { name = "database.password", value = local.postgresql_password },
    { name = "postgresql.enabled", value = "false" },
  ]

  # Node selector values
  node_selector_values = [
    for key, value in var.node_selector : {
      name  = "nodeSelector.${key}"
      value = value
    }
  ]

  # Tolerations values
  tolerations_values = flatten([
    for idx, t in var.tolerations : [
      { name = "tolerations[${idx}].key", value = t.key },
      { name = "tolerations[${idx}].operator", value = t.operator },
      t.value != null ? [{ name = "tolerations[${idx}].value", value = t.value }] : [],
      t.effect != null ? [{ name = "tolerations[${idx}].effect", value = t.effect }] : [],
    ]
  ])

  # Ingress set values (without annotations that have special characters)
  ingress_set_values = var.create_ingress ? [
    { name = "ingress.enabled", value = "true" },
    { name = "ingress.ingressClassName", value = var.ingress_class_name },
    { name = "ingress.rules[0].host", value = var.ingress_hostname },
    { name = "ingress.rules[0].paths[0].path", value = "/" },
    { name = "ingress.rules[0].paths[0].pathType", value = "Prefix" },
    ] : [
    { name = "ingress.enabled", value = "false" },
  ]

  # Storage class value
  storage_class_values = var.storage_class_name != "" ? [
    { name = "postgresql.primary.persistence.storageClass", value = var.storage_class_name },
  ] : []

  # YAML values for ingress annotations (handles special characters better)
  ingress_annotations_yaml = var.create_ingress && var.ingress_class_name == "alb" ? yamlencode({
    ingress = {
      annotations = {
        "alb.ingress.kubernetes.io/group.name"   = var.ingress_group_name
        "alb.ingress.kubernetes.io/target-type"  = "ip"
        "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
        "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      }
    }
  }) : ""
}

resource "helm_release" "keycloak" {
  name             = var.helm_release_name
  repository       = "https://codecentric.github.io/helm-charts"
  chart            = "keycloakx"
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  # Use values for complex nested structures with special characters
  values = local.ingress_annotations_yaml != "" ? [local.ingress_annotations_yaml] : []

  set = concat(
    # Keycloak startup command
    [
      { name = "command[0]", value = "/opt/keycloak/bin/kc.sh" },
      { name = "args[0]", value = "start" },
      { name = "args[1]", value = "--http-enabled=true" },
      { name = "args[2]", value = "--hostname-strict=false" },
    ],
    # Admin credentials
    [
      { name = "extraEnv[0].name", value = "KEYCLOAK_ADMIN" },
      { name = "extraEnv[0].value", value = local.keycloak_username },
      { name = "extraEnv[1].name", value = "KEYCLOAK_ADMIN_PASSWORD" },
      { name = "extraEnv[1].value", value = local.keycloak_password },
      { name = "extraEnv[2].name", value = "JAVA_OPTS_APPEND" },
      { name = "extraEnv[2].value", value = "-Djgroups.dns.query=${var.helm_release_name}-headless" },
    ],
    # Database configuration
    local.database_set_values,
    # Resources
    [
      { name = "resources.requests.cpu", value = var.keycloak_cpu },
      { name = "resources.requests.memory", value = var.keycloak_memory },
      { name = "resources.limits.cpu", value = var.keycloak_cpu },
      { name = "resources.limits.memory", value = var.keycloak_memory },
    ],
    # Replicas
    [
      { name = "replicas", value = tostring(var.replicas) },
    ],
    # Storage class
    local.storage_class_values,
    # Node selector
    local.node_selector_values,
    # Tolerations
    local.tolerations_values,
    # Ingress basic config
    local.ingress_set_values,
    # Service configuration
    [
      { name = "service.type", value = "ClusterIP" },
    ],
    # HTTP configuration for proxy
    [
      { name = "proxy.enabled", value = "true" },
      { name = "proxy.mode", value = "edge" },
    ],
  )

  lifecycle {
    ignore_changes = [
      timeout
    ]
  }
}
