# deploys the configuration for the AKS OSM agent (which is the Azure Monitor agent running on AKS)
resource kubernetes_config_map osm_agent_config {
  metadata {
    name = "container-azm-ms-agentconfig"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "container-azm-ms-agentconfig"
      "app.kubernetes.io/component" = "omsagent"
      "app.kubernetes.io/part-of" = "omsagent"
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }
  data = {
    schema-version = "v1"
    config-version = "ver1"
    log-data-collection-settings = file("${path.module}/resources/oms-agent-log-data-collection-settings.txt")
    prometheus-data-collection-settings = file("${path.module}/resources/oms-agent-prometheus-data-collection-settings.txt")
    metric_collection_settings = file("${path.module}/resources/oms-agent-metric-collection-settings.txt")
    alertable-metrics-configuration-settings = file("${path.module}/resources/oms-agent-alertable-metrics-configuration-settings.txt")
    integrations = file("${path.module}/resources/oms-agent-integrations.txt")
  }
}