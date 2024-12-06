resource "helm_release" "prometheus_operator_crds" {
  depends_on = [
    azurerm_kubernetes_cluster.k6tests
  ]
  name       = "prometheus-operator-crds"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-operator-crds"
  version    = "16.0.1"
}

resource "helm_release" "kube_prometheus_stack" {
  depends_on = [
    helm_release.prometheus_operator_crds,
    azuread_application.prometheus,
    azurerm_monitor_workspace.k6tests_amw
  ]
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  skip_crds        = true
  version          = "66.3.1"

  values = [
    "${templatefile(
      "${path.module}/k6_tests_rg_kube_prometheus_stack_values.tftpl",
      {
        cluster_name          = "${azurerm_kubernetes_cluster.k6tests.name}",
        client_id             = "${azuread_application.prometheus.client_id}",
        tenant_id             = "${data.azurerm_client_config.current.tenant_id}",
        remote_write_endpoint = "${azurerm_monitor_workspace.k6tests_amw.default_data_collection_rule_id}"
      }
    )}"
  ]
}

resource "azuread_application" "prometheus" {
  display_name     = "adminservicestest-k6tests-prometheus"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "prometheus" {
  client_id = azuread_application.prometheus.client_id
}

resource "azuread_application_federated_identity_credential" "prometheus" {
  application_id = azuread_application.prometheus.id
  display_name   = "adminservicestest-k6tests-prometheus"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = azurerm_kubernetes_cluster.k6tests.oidc_issuer_url
  subject        = "system:serviceaccount:monitoring:kube-prometheus-stack-prometheus"
}

resource "azurerm_role_assignment" "monitoring_metrics_publisher" {
  scope                = azurerm_monitor_workspace.k6tests_amw.default_data_collection_endpoint_id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azuread_service_principal.prometheus.id
}