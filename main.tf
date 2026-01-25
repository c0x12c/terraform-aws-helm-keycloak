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

  # Storage class value
  storage_class_values = var.storage_class_name != "" ? [
    { name = "postgresql.primary.persistence.storageClass", value = var.storage_class_name },
  ] : []

  # YAML values for complex configurations
  helm_values = yamlencode({
    # Extra environment variables (must be a YAML string in keycloakx)
    extraEnv = <<-EOT
      - name: KEYCLOAK_ADMIN
        value: "${local.keycloak_username}"
      - name: KEYCLOAK_ADMIN_PASSWORD
        value: "${local.keycloak_password}"
      - name: JAVA_OPTS_APPEND
        value: "-Djgroups.dns.query=${var.helm_release_name}-headless"
    EOT

    # Full ingress configuration
    ingress = {
      enabled          = var.create_ingress
      ingressClassName = var.create_ingress ? var.ingress_class_name : ""
      servicePort      = "http"
      annotations = var.create_ingress && var.ingress_class_name == "alb" ? {
        "kubernetes.io/ingress.class"                = "alb"
        "alb.ingress.kubernetes.io/group.name"       = var.ingress_group_name
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/health/ready"
        "alb.ingress.kubernetes.io/healthcheck-port" = "8080"
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      } : {}
      rules = var.create_ingress ? [
        {
          host = var.ingress_hostname
          paths = [
            {
              path     = "/*"
              pathType = "ImplementationSpecific"
            }
          ]
        }
      ] : []
      tls = []
    }

    # Service configuration - map to Keycloak's default HTTP port 8080
    service = {
      httpPort = 8080
    }
  })
}

resource "helm_release" "keycloak" {
  name             = var.helm_release_name
  repository       = "https://codecentric.github.io/helm-charts"
  chart            = "keycloakx"
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  # Use values for complex nested structures
  values = [local.helm_values]

  set = concat(
    # Keycloak startup command
    [
      { name = "command[0]", value = "/opt/keycloak/bin/kc.sh" },
      { name = "args[0]", value = "start" },
      { name = "args[1]", value = "--http-enabled=true" },
      { name = "args[2]", value = "--hostname-strict=false" },
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
    # Service configuration
    [
      { name = "service.type", value = "ClusterIP" },
    ],
    # HTTP configuration for proxy
    [
      { name = "proxy.enabled", value = "true" },
      { name = "proxy.mode", value = "xforwarded" },
    ],
  )

  lifecycle {
    ignore_changes = [
      timeout
    ]
  }
}
