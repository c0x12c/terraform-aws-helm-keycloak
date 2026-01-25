resource "kubernetes_ingress_v1" "keycloak" {
  count = var.create_ingress ? 1 : 0

  metadata {
    name      = var.helm_release_name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class"                = var.ingress_class_name
      "alb.ingress.kubernetes.io/group.name"       = var.ingress_group_name
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ "HTTP" = 80 }, { "HTTPS" = 443 }])
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/health"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.ingress_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = var.helm_release_name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.keycloak]
}
