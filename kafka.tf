locals {
  kafka_name = "confluent"
}

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "${local.kafka_k8s_namespace}"
  }
}

data "helm_repository" "confluentinc" {
  name = "confluentinc"

  # cp-helm-charts 0.1.1
  url = "https://raw.githubusercontent.com/lsst-sqre/cp-helm-charts/subchart-test/charts"
}

# cp-kafka includes cp-zookeeper
resource "helm_release" "cp_kafka" {
  name       = "${local.kafka_name}"
  repository = "${data.helm_repository.confluentinc.metadata.0.name}"
  chart      = "cp-kafka"
  namespace  = "${kubernetes_namespace.kafka.metadata.0.name}"
  version    = "0.1.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.cp_kafka_values.rendered}",
  ]
}

data "template_file" "cp_kafka_values" {
  template = "${file("${path.module}/charts/cp-kafka.yaml")}"

  vars {
    brokers_disk_size       = "${var.brokers_disk_size}"
    deploy_name             = "${var.deploy_name}"
    dns_prefix              = "${local.dns_prefix}"
    domain_name             = "${var.domain_name}"
    zookeeper_data_dir_size = "${var.zookeeper_data_dir_size}"
    zookeeper_log_dir_size  = "${var.zookeeper_log_dir_size}"
    storage_class           = "${var.storage_class}"
  }
}

resource "helm_release" "cp_kafka_connect" {
  name       = "cp-kafka-connect"
  repository = "${data.helm_repository.confluentinc.metadata.0.name}"
  chart      = "cp-kafka-connect"
  namespace  = "${kubernetes_namespace.kafka.metadata.0.name}"
  version    = "0.1.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.cp_kafka_connect_values.rendered}",
  ]

  depends_on = ["helm_release.cp_kafka"]
}

data "template_file" "cp_kafka_connect_values" {
  template = "${file("${path.module}/charts/cp-kafka-connect.yaml")}"
}

resource "helm_release" "cp_kafka_rest" {
  name       = "cp-kafka-rest"
  repository = "${data.helm_repository.confluentinc.metadata.0.name}"
  chart      = "cp-kafka-rest"
  namespace  = "${kubernetes_namespace.kafka.metadata.0.name}"
  version    = "0.1.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.cp_kafka_rest_values.rendered}",
  ]

  depends_on = ["helm_release.cp_kafka"]
}

data "template_file" "cp_kafka_rest_values" {
  template = "${file("${path.module}/charts/cp-kafka-rest.yaml")}"
}

resource "helm_release" "cp_ksql_server" {
  name       = "cp-ksql-server"
  repository = "${data.helm_repository.confluentinc.metadata.0.name}"
  chart      = "cp-ksql-server"
  namespace  = "${kubernetes_namespace.kafka.metadata.0.name}"
  version    = "0.1.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.cp_ksql_server_values.rendered}",
  ]
}

data "template_file" "cp_ksql_server_values" {
  template = "${file("${path.module}/charts/cp-ksql-server.yaml")}"
}

resource "helm_release" "cp_schema_registry" {
  name       = "cp-schema-registry"
  repository = "${data.helm_repository.confluentinc.metadata.0.name}"
  chart      = "cp-schema-registry"
  namespace  = "${kubernetes_namespace.kafka.metadata.0.name}"
  version    = "0.1.0"

  force_update  = true
  recreate_pods = true

  values = [
    "${data.template_file.cp_schema_registry_values.rendered}",
  ]

  depends_on = ["helm_release.cp_kafka"]
}

data "template_file" "cp_schema_registry_values" {
  template = "${file("${path.module}/charts/cp-schema-registry.yaml")}"
}

data "kubernetes_service" "lb0" {
  metadata {
    name      = "${local.kafka_name}-0-loadbalancer"
    namespace = "${kubernetes_namespace.kafka.metadata.0.name}"
  }

  depends_on = ["helm_release.cp_kafka"]
}

data "kubernetes_service" "lb1" {
  metadata {
    name      = "${local.kafka_name}-1-loadbalancer"
    namespace = "${kubernetes_namespace.kafka.metadata.0.name}"
  }

  depends_on = ["helm_release.cp_kafka"]
}

data "kubernetes_service" "lb2" {
  metadata {
    name      = "${local.kafka_name}-2-loadbalancer"
    namespace = "${kubernetes_namespace.kafka.metadata.0.name}"
  }

  depends_on = ["helm_release.cp_kafka"]
}

locals {
  confluent_lb0_ip = "${lookup(data.kubernetes_service.lb0.load_balancer_ingress[0], "ip")}"
  confluent_lb1_ip = "${lookup(data.kubernetes_service.lb1.load_balancer_ingress[0], "ip")}"
  confluent_lb2_ip = "${lookup(data.kubernetes_service.lb2.load_balancer_ingress[0], "ip")}"
}
