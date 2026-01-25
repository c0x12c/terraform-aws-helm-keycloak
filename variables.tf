variable "namespace" {
  description = "The Namespace of the services."
  type        = string
  default     = "keycloak"
}

variable "helm_release_name" {
  description = "The Helm release of the services."
  type        = string
  default     = "keycloak"
}

variable "helm_chart_version" {
  default     = "2.4.4"
  type        = string
  description = "The chart version of keycloakx (codecentric)"
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Determines whether a new namespace should be created. Set to 'true' to create the namespace; otherwise, set to 'false' to use an existing namespace."
}

variable "replicas" {
  type        = number
  description = "Number of Keycloak replicas"
  default     = 1
}

variable "keycloak_cpu" {
  type        = string
  description = "Keycloak cpu"
  default     = "450m"
}

variable "keycloak_memory" {
  type        = string
  description = "Keycloak memory"
  default     = "1024Mi"
}

variable "create_postgresql" {
  type        = bool
  default     = true
  description = "Whether to deploy a PostgreSQL instance via the chart's subchart"
}

variable "postgresql_db_name" {
  type        = string
  description = "Name of the database"
  default     = "keycloak"
}

variable "postgresql_username" {
  type        = string
  description = "Username for the database"
  default     = "keycloak"
}

variable "postgresql_password" {
  type        = string
  description = "Password for the database"
  default     = null
  sensitive   = true
}

variable "postgresql_host" {
  type        = string
  description = "Host for the external database"
  default     = ""
}

variable "postgresql_port" {
  type        = number
  description = "Port for the external database"
  default     = 5432
}

variable "storage_class_name" {
  type        = string
  description = "Storage class name"
  default     = ""
}

variable "create_ingress" {
  type        = bool
  description = "Whether to create the ingress"
  default     = true
}

variable "ingress_class_name" {
  type        = string
  description = "Ingress class name"
  default     = "alb"
}

variable "ingress_group_name" {
  type        = string
  description = "ALB ingress group name to join"
  default     = "external"
}

variable "ingress_hostname" {
  type        = string
  description = "Hostname for the ingress"
  default     = ""
}

variable "node_selector" {
  description = "Node selector for the keycloak"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for the keycloak"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}
