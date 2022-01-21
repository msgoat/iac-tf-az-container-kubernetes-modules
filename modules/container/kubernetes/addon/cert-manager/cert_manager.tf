# create a namespace for hello application
resource kubernetes_namespace cert_manager {
  count = var.addon_enabled ? 1 : 0
  metadata {
    name = "cert-manager"
    labels = {
      "istio-injection" = "disabled"
    }
  }
}

# deploys Azure AD Pod Identity controller on AKS cluster
resource helm_release cert_manager {
  count = var.addon_enabled ? 1 : 0
  name = "cert-manager"
  chart = "cert-manager"
  namespace = kubernetes_namespace.cert_manager[0].metadata[0].name
  create_namespace = false
  dependency_update = true
  repository = "https://charts.jetstack.io"
  atomic = true
  cleanup_on_fail = true
  set {
    name = "global.leaderElection.namespace"
    value = kubernetes_namespace.cert_manager[0].metadata[0].name
  }
  set {
    name = "installCRDs"
    value = "true"
  }
  set {
    name = "image.tag"
    value = "v1.2.0"
  }
  set {
    name = "nodeSelector.agentpool"
    value = "user"
  }
  set {
    name = "webhook.nodeSelector.agentpool"
    value = "user"
  }
  set {
    name = "cainjector.nodeSelector.agentpool"
    value = "user"
  }
  # @TODO: add securityContext on pod and container level
}
