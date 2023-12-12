resource "random_id" "salt" {
  byte_length = 4
}

resource "azurerm_resource_group" "test" {
  location = var.location
  name     = "${var.project}-${random_id.salt.hex}"
}

locals {
  counting_app_name  = "counting-${random_id.salt.hex}"
  dashboard_app_name = "dashboard-${random_id.salt.hex}"
  http_echo_app_name = "http-echo-${random_id.salt.hex}"
}

module "container_apps" {
  source                                                   = "./aca"
  resource_group_name                                      = azurerm_resource_group.test.name
  location                                                 = var.location
  container_app_environment_name                           = "cae-${var.project}-${random_id.salt.hex}"
  container_app_environment_internal_load_balancer_enabled = null
  container_apps = {
    http_echo = {
      name          = local.http_echo_app_name
      revision_mode = "Single"
      template = {
        containers = [
          {
            name   = "http-echo"
            memory = "0.5Gi"
            cpu    = 0.25
            image  = "docker.io/mendhak/http-https-echo:latest"
            env = [
            ]
          }
        ]

      }
      ingress = {
        allow_insecure_connections = false
        target_port                = 8080
        external_enabled           = true

        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      identity = {
        type = "SystemAssigned"
      }
    }
    counting = {
      name          = local.counting_app_name
      revision_mode = "Single"

      template = {
        containers = [
          {
            name   = "countingservicetest1"
            memory = "0.5Gi"
            cpu    = 0.25
            image  = "docker.io/hashicorp/counting-service:0.0.2"
            env = [
              {
                name  = "PORT"
                value = "9001"
              }
            ]
          },
        ]
      }

      ingress = {
        allow_insecure_connections = true
        external_enabled           = false
        target_port                = 9001
        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
    },
    dashboard = {
      name          = local.dashboard_app_name
      revision_mode = "Single"

      template = {
        containers = [
          {
            name   = "testdashboard"
            memory = "1Gi"
            cpu    = 0.5
            image  = "docker.io/hashicorp/dashboard-service:0.0.4"
            env = [
              {
                name  = "PORT"
                value = "8080"
              },
              {
                name  = "COUNTING_SERVICE_URL"
                value = "http://${local.counting_app_name}"
              }
            ]
          },
        ]
      }

      ingress = {
        allow_insecure_connections = false
        target_port                = 8080
        external_enabled           = true

        traffic_weight = {
          latest_revision = true
          percentage      = 100
        }
      }
      identity = {
        type = "SystemAssigned"
      }
    },
  }
  log_analytics_workspace_name = "law-${var.project}-${random_id.salt.hex}"
}
