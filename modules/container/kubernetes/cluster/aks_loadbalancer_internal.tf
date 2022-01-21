locals {
  internal_lb_service_name = "internal-lb-trigger"
}

# creates a virtual service which triggers the creation of an internal loadbalancer instead of an external one
resource kubernetes_service internal_lb {
  count = var.internal_loadbalancer_enabled ? 1 : 0
  metadata {
    name = local.internal_lb_service_name
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = local.internal_lb_service_name
      "app.kubernetes.io/component" = "network"
      "app.kubernetes.io/part-of" = var.solution_name
      "app.kubernetes.io/managed-by" = "Terraform"
    }
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
      "service.beta.kubernetes.io/azure-load-balancer-internal-subnet" = var.internal_loadbalancer_subnet_name
    }
  }
  spec {
    selector = {
      app = local.internal_lb_service_name
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}

# wait until internal loadbalancer has been created
resource time_sleep wait_for_internal_lb {
  count = var.internal_loadbalancer_enabled ? 1 : 0
  create_duration = "60s"
  depends_on = [ kubernetes_service.internal_lb ]
}

# retrieve the external loadbalancer managed by the AKS cluster
data azurerm_lb internal {
  count = var.internal_loadbalancer_enabled ? 1 : 0
  name = "kubernetes-internal"
  resource_group_name = azurerm_kubernetes_cluster.cluster.node_resource_group
  depends_on = [ time_sleep.wait_for_internal_lb ]
}