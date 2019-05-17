terraform efd "app" deployment
===

[![Build Status](https://travis-ci.org/lsst-sqre/terraform-efd.png)](https://travis-ci.org/lsst-sqre/terraform-efd)

Deploys an `efd` instance onto a k8s cluster.

Usage
---

```terraform
provider "aws" {
  version = "~> 2.10.0"
  region  = "us-east-1"
}

provider "kubernetes" {
  version = "~> 1.6.2"

  config_path      = "/tmp/kubeconfig"
  load_config_file = true
}

module "efd" {
  source = "git::git@github.com:lsst-sqre/terraform-efd.git//?ref=master"

  aws_zone_id                    = "${var.aws_zone_id}"
  brokers_disk_size              = "${var.brokers_disk_size}"
  deploy_name                    = "${var.deploy_name}"
  dns_enable                     = "${var.dns_enable}"
  domain_name                    = "${var.domain_name}"
  env_name                       = "${var.env_name}"
  github_token                   = "${var.github_token}"
  github_user                    = "${var.github_user}"
  grafana_admin_pass             = "${var.grafana_admin_pass}"
  grafana_admin_user             = "${var.grafana_admin_user}"
  grafana_oauth_client_id        = "${var.grafana_oauth_client_id}"
  grafana_oauth_client_secret    = "${var.grafana_oauth_client_secret}"
  grafana_oauth_team_ids         = "${var.grafana_oauth_team_ids}"
  influxdb_admin_pass            = "${var.influxdb_admin_pass}"
  influxdb_admin_user            = "${var.influxdb_admin_user}"
  influxdb_telegraf_pass         = "${var.influxdb_telegraf_pass}"
  kubeconfig_filename            = "/tmp/kubeconfig"
  prometheus_oauth_client_id     = "${var.prometheus_oauth_client_id}"
  prometheus_oauth_client_secret = "${var.prometheus_oauth_client_secret}"
  prometheus_oauth_github_org    = "${var.prometheus_oauth_github_org}"
  tls_crt_path                   = "${var.tls_crt_path}"
  tls_key_path                   = "${var.tls_key_path}"
  zookeeper_data_dir_size        = "${var.zookeeper_data_dir_size}"
  zookeeper_log_dir_size         = "${var.zookeeper_log_dir_size}"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_zone\_id | route53 Hosted Zone ID to manage DNS records in. | string | n/a | yes |
| brokers\_disk\_size | Disk size for the cp-kafka brokers. | string | `"15Gi"` | no |
| deploy\_name | Name of deployment. | string | `"efd"` | no |
| dns\_enable | create route53 dns records. | string | `"false"` | no |
| dns\_overwrite | overwrite pre-existing DNS records. | string | `"false"` | no |
| domain\_name | DNS domain name to use when creating route53 records. | string | n/a | yes |
| env\_name | Name of deployment environment. | string | n/a | yes |
| github\_token | GitHub personal access token for authenticating to the GitHub API | string | n/a | yes |
| github\_user | GitHub username for authenticating to the GitHub API. | string | n/a | yes |
| grafana\_admin\_pass | grafana admin account passphrase. | string | n/a | yes |
| grafana\_admin\_user | grafana admin account name. | string | `"admin"` | no |
| grafana\_oauth\_client\_id | github oauth Client ID for grafana | string | n/a | yes |
| grafana\_oauth\_client\_secret | github oauth Client Secret for grafana. | string | n/a | yes |
| grafana\_oauth\_team\_ids | github team id (integer value treated as string) | string | n/a | yes |
| influxdb\_admin\_pass | influxdb admin account passphrase. | string | n/a | yes |
| influxdb\_admin\_user | influxdb admin account name. | string | `"admin"` | no |
| influxdb\_telegraf\_pass | InfluxDB password for the telegraf user. | string | n/a | yes |
| kubeconfig\_filename | kubeconfig file to configure kubernetes/helm providers | string | n/a | yes |
| prometheus\_oauth\_client\_id | github oauth client id | string | n/a | yes |
| prometheus\_oauth\_client\_secret | github oauth client secret | string | n/a | yes |
| prometheus\_oauth\_github\_org | limit access to prometheus dashboard to members of this org | string | n/a | yes |
| tls\_crt\_path | wildcard tls certificate. | string | n/a | yes |
| tls\_key\_path | wildcard tls private key. | string | n/a | yes |
| zookeeper\_data\_dir\_size | Size for Data dir, where ZooKeeper will store the in-memory database snapshots. | string | `"15Gi"` | no |
| zookeeper\_log\_dir\_size | Size for data log dir, which is a dedicated log device to be used, and helps avoid competition between logging and snaphots. | string | `"15Gi"` | no |

## Outputs

| Name | Description |
|------|-------------|
| confluent\_lb0 |  |
| confluent\_lb1 |  |
| confluent\_lb2 |  |
| grafana\_fqdn |  |
| influxdb\_fqdn |  |
| nginx\_ingress\_ip |  |
| prometheus\_fqdn |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

`helm`
---

Note that the `helm` provider is used, which requires an initialized `helm`
repo configuration.

`pre-commit` hooks
---

```bash
go get github.com/segmentio/terraform-docs
pip install --user pre-commit
pre-commit install

# manual run
pre-commit run -a
```

See Also
---

* [`terraform`](https://www.terraform.io/)
* [`terraform-docs`](https://github.com/segmentio/terraform-docs)
* [`helm`](https://docs.helm.sh/)
* [`pre-commit`](https://github.com/pre-commit/pre-commit)
* [`pre-commit-terraform`](https://github.com/antonbabenko/pre-commit-terraform)
