provider "kubernetes" {}

resource "kubernetes_namespace" "country" {
  metadata {
    name = "country"

    labels = {
      label = "country"
    }
  }
  provisioner "local-exec" {
    command = "kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/z/.docker/config.json --type=kubernetes.io/dockerconfigjson --namespace country"
  }
}

resource "kubernetes_namespace" "air" {
  metadata {
    name = "air"

    labels = {
      label = "air"
    }
  }
  provisioner "local-exec" {
    command = "kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/z/.docker/config.json --type=kubernetes.io/dockerconfigjson --namespace air"
  }
}

resource "kubernetes_deployment" "country_102" {
  metadata {
    name      = "country102"
    namespace = "country"

    labels = {
      run = "country102"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        run = "country102"
      }
    }

    template {
      metadata {
        labels = {
          run = "country102"
        }
      }

      spec {
        container {
          name  = "country102"
          image = "ztoth123/aircountries:country102"

          liveness_probe {
            http_get {
              path = "/health/live"
              port = "8080"
            }

            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health/ready"
              port = "8080"
            }

            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }

        image_pull_secrets {
          name = "regcred"
        }
      }
    }
  }
}

resource "kubernetes_service" "air_103_service" {
  metadata {
    name      = "air103-service"
    namespace = "air"

    labels = {
      run = "air103"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = "8080"
      target_port = "8080"
    }

    selector = {
      run = "air103"
    }

    type             = "ClusterIP"
    session_affinity = "None"
  }
}

resource "kubernetes_network_policy" "air_default_deny_all" {
  metadata {
    name      = "air-default-deny-all"
    namespace = "air"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "air_permit_network_policy" {
  metadata {
    name      = "air-permit-network-policy"
    namespace = "air"
  }

  spec {
    pod_selector {}

    ingress {
      ports {
        protocol = "TCP"
        port     = "8080"
      }

      from {
        namespace_selector {
          match_labels = {
            label = "air"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "country_default_deny_all" {
  metadata {
    name      = "country-default-deny-all"
    namespace = "country"
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "country_permit_network_policy" {
  metadata {
    name      = "country-permit-network-policy"
    namespace = "country"
  }

  spec {
    pod_selector {}

    ingress {
      ports {
        protocol = "TCP"
        port     = "8080"
      }

      from {
        namespace_selector {
          match_labels = {
            label = "country"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_service" "country_102_service" {
  metadata {
    name      = "country102-service"
    namespace = "country"

    labels = {
      run = "country102"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = "8080"
      target_port = "8080"
    }

    selector = {
      run = "country102"
    }

    type             = "ClusterIP"
    session_affinity = "None"
  }
}

resource "kubernetes_deployment" "air_103" {
  metadata {
    name      = "air103"
    namespace = "air"

    labels = {
      run = "air103"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        run = "air103"
      }
    }

    template {
      metadata {
        labels = {
          run = "air103"
        }
      }

      spec {
        container {
          name  = "air103"
          image = "ztoth123/aircountries:air112"

          liveness_probe {
            http_get {
              path = "/health/live"
              port = "8080"
            }

            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health/ready"
              port = "8080"
            }

            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }

        image_pull_secrets {
          name = "regcred"
        }
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "50%"
        max_surge       = "50%"
      }
    }
  }
}

resource "kubernetes_ingress" "air_ingress" {
  metadata {
    name      = "air-ingress"
    namespace = "air"

    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "air-country.lunatest.nl"

      http {
        path {
          path = "/airports"

          backend {
            service_name = "air103-service"
            service_port = "8080"
          }
        }

        path {
          path = "/airports/"

          backend {
            service_name = "air103-service"
            service_port = "8080"
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "countries_ingress" {
  metadata {
    name      = "countries-ingress"
    namespace = "country"

    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "air-country.lunatest.nl"

      http {
        path {
          path = "/countries"

          backend {
            service_name = "country102-service"
            service_port = "8080"
          }
        }

        path {
          path = "/countries/"

          backend {
            service_name = "country102-service"
            service_port = "8080"
          }
        }
      }
    }
  }
}
resource "kubernetes_pod" "testpod-in-air" {
  metadata {
    name = "airtestpod"
    namespace = "air"
  }

  spec {
    container {
      image = "alpine"
      name  = "airtestcontainer"
      command = ["sleep", "120000"]
    }
  }
}

resource "kubernetes_pod" "testpod-in-country" {
  metadata {
    name = "countrytestpod"
    namespace = "country"
  }

  spec {
    container {
      image = "alpine"
      name  = "countrytestcontainer"
      command = ["sleep", "120000"]
    }
  }
}