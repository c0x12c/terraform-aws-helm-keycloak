output "keycloak_username" {
  value = local.keycloak_username
}

output "keycloak_password" {
  value     = local.keycloak_password
  sensitive = true
}

output "helm_values" {
  description = "The computed Helm values YAML"
  value       = local.manifest
}
