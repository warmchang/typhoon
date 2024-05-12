# Kubernetes assets (kubeconfig, manifests)
module "bootstrap" {
  source = "git::https://github.com/poseidon/terraform-render-bootstrap.git?ref=baf406f2616f9536af2e09d969c8b6a87dc3ed17"

  cluster_name = var.cluster_name
  api_servers  = [format("%s.%s", var.cluster_name, var.dns_zone)]
  etcd_servers = digitalocean_record.etcds.*.fqdn

  networking = var.install_container_networking ? var.networking : "none"
  # only effective with Calico networking
  network_encapsulation = "vxlan"
  network_mtu           = "1450"

  pod_cidr              = var.pod_cidr
  service_cidr          = var.service_cidr
  cluster_domain_suffix = var.cluster_domain_suffix
  enable_reporting      = var.enable_reporting
  enable_aggregation    = var.enable_aggregation
}

