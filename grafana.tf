locals {
  grafana_fqdn = "${local.dns_prefix}grafana-${var.deploy_name}.${var.domain_name}"
  grafana_secret_name = "grafana-server-tls"
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "${local.grafana_k8s_namespace}"
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "stable/grafana"
  namespace  = "${local.grafana_k8s_namespace}"
  version    = "1.20.0"

  keyring       = ""
  force_update  = true
  recreate_pods = true

  values = [
    "${file("${path.module}/charts/grafana.yaml")}",
    "${data.template_file.grafana_values.rendered}",
  ]

  depends_on = [
    "module.tiller",
    "kubernetes_secret.grafana_tls",
    "helm_release.nginx_ingress",
  ]
}

resource "kubernetes_secret" "grafana_tls" {
  metadata {
    name      = "${local.grafana_secret_name}"
    namespace = "${local.grafana_k8s_namespace}"
  }

  data {
    tls.crt = "${local.tls_crt}"
    tls.key = "${local.tls_key}"
  }
}

data "template_file" "grafana_values" {
  template = <<EOF
---
adminUser: $${grafana_admin_user}
adminPassword: $${grafana_admin_pass}
service:
  # ingress on gke requires "NodePort" or "LoadBalancer"
  type: NodePort
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/proxy-body-size: "0m"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-Port 443;
      proxy_set_header X-Forwarded-Path /;
  hosts:
    - $${grafana_fqdn}
  tls:
    - secretName: $${grafana_secret_name}
      hosts:
        - $${grafana_fqdn}
# Add Prometheus as the default datasource
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.$${prometheus_k8s_namespace}.svc.cluster.local
      access: proxy
      isDefault: true
grafana.ini:
  auth.github:
    enabled: true
    client_id: $${client_id}
    client_secret: $${client_secret}
    scopes: user:email,read:org
    auth_url: https://github.com/login/oauth/authorize
    token_url: https://github.com/login/oauth/access_token
    api_url: https://api.github.com/user
    allow_sign_up: true
    # space-delimited organization names
    #allowed_organizations:
    # comma seperated list of team ids
    team_ids: "$${team_ids}"
  server:
    root_url: https://$${grafana_fqdn}
  users:
    auto_assign_org_role: Admin
dashboardproviders.yaml:
  apiVersion: 1
  providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 15
    editable: true
    options:
      path: /var/lib/grafana/dashboards/default
# the init container url download appears to be broken...
#dashboards:
#  default:
#    some-dashboard:
#      url: https://raw.githubusercontent.com/confluentinc/cp-helm-charts/700b4326352cf5220e66e6976064740b8c1976c7/grafana-dashboard/confluent-open-source-grafana-dashboard.json
EOF

  vars {
    grafana_fqdn             = "${local.grafana_fqdn}"
    grafana_secret_name      = "${local.grafana_secret_name}"
    grafana_admin_user       = "${var.grafana_admin_user}"
    grafana_admin_pass       = "${var.grafana_admin_pass}"
    prometheus_k8s_namespace = "${local.prometheus_k8s_namespace}"
    client_id                = "${var.grafana_oauth_client_id}"
    client_secret            = "${var.grafana_oauth_client_secret}"
    team_ids                 = "${var.grafana_oauth_team_ids}"
  }
}

provider "grafana" {
  url  = "https://${local.grafana_fqdn}"
  auth = "${var.grafana_admin_user}:${var.grafana_admin_pass}"
}

resource "grafana_dashboard" "confluent" {
  config_json = "${data.template_file.confluent_grafana_dashboard.rendered}"

  depends_on = ["helm_release.grafana"]
}

# confluent dashboard copied from:
# https://raw.githubusercontent.com/confluentinc/cp-helm-charts/700b4326352cf5220e66e6976064740b8c1976c7/grafana-dashboard/confluent-open-source-grafana-dashboard.json
data "template_file" "confluent_grafana_dashboard" {
  template = "${file("${path.module}/grafana-dashboards/confluent-open-source-grafana-dashboard.json")}"

  # The confluent provided json includes the variable `${DS_PROMETHEUS}` to be
  # templated by grafana.  However, neither the stable/grafana chart or the
  # current tf grafana provider is able to configure "variables".
  # Coincidentally, this is the same format tf uses for templates...
  vars {
    DS_PROMETHEUS = "Prometheus"
  }
}

resource "grafana_dashboard" "nginx" {
  config_json = "${data.template_file.nginx_grafana_dashboard.rendered}"

  depends_on = ["helm_release.grafana"]
}

# nginx dashboard copied from:
# https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/grafana/dashboards/nginx.yaml
data "template_file" "nginx_grafana_dashboard" {
  template = "${file("${path.module}/grafana-dashboards/nginx.yaml")}"

  vars {
    DS_PROMETHEUS = "Prometheus"
  }
}
