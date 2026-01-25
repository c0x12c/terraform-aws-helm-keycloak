module "example" {
  source = "../.."

  # External PostgreSQL configuration
  create_postgresql   = false
  postgresql_host     = "db_host"
  postgresql_port     = 5432
  postgresql_db_name  = "db_name"
  postgresql_username = "db_username"
  postgresql_password = "db_password"

  # Ingress configuration (ALB)
  create_ingress     = true
  ingress_class_name = "alb"
  ingress_group_name = "external"
  ingress_hostname   = "keycloak.example.com"

  # Resources
  replicas        = 1
  keycloak_cpu    = "500m"
  keycloak_memory = "1024Mi"

  node_selector = {}
  tolerations   = []
}
