# Kubernetes assets (kubeconfig, manifests)
module "bootstrap" {
  source = "git::https://github.com/poseidon/terraform-render-bootstrap.git?ref=9af5837c35411939111dff1b00e52faf26b179a2"

  cluster_name           = var.cluster_name
  etcd_servers           = [for fqdn in google_dns_record_set.etcds.*.name : trimsuffix(fqdn, ".")]
  api_servers            = [format("%s.%s", var.cluster_name, var.dns_zone)]
  service_account_issuer = var.service_account_issuer
  networking             = var.networking
  pod_cidr               = var.pod_cidr
  service_cidr           = var.service_cidr
  daemonset_tolerations  = var.daemonset_tolerations
  components             = var.components
}
