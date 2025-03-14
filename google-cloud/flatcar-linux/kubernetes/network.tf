resource "google_compute_network" "network" {
  name                    = var.cluster_name
  description             = "Network for the ${var.cluster_name} cluster"
  auto_create_subnetworks = true

  timeouts {
    delete = "6m"
  }
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "${var.cluster_name}-allow-ssh"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [22]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
}

resource "google_compute_firewall" "internal-etcd" {
  name    = "${var.cluster_name}-internal-etcd"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [2379, 2380]
  }

  source_tags = ["${var.cluster_name}-controller"]
  target_tags = ["${var.cluster_name}-controller"]
}

# Allow Prometheus to scrape etcd metrics
resource "google_compute_firewall" "internal-etcd-metrics" {
  name    = "${var.cluster_name}-internal-etcd-metrics"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [2381]
  }

  source_tags = ["${var.cluster_name}-worker"]
  target_tags = ["${var.cluster_name}-controller"]
}

# Allow Prometheus to scrape kube-scheduler and kube-controller-manager metrics
resource "google_compute_firewall" "internal-kube-metrics" {
  name    = "${var.cluster_name}-internal-kube-metrics"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [10257, 10259]
  }

  source_tags = ["${var.cluster_name}-worker"]
  target_tags = ["${var.cluster_name}-controller"]
}

resource "google_compute_firewall" "allow-apiserver" {
  name    = "${var.cluster_name}-allow-apiserver"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [6443]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.cluster_name}-controller"]
}

# flannel
resource "google_compute_firewall" "internal-flannel" {
  count = var.networking == "flannel" ? 1 : 0

  name    = "${var.cluster_name}-flannel"
  network = google_compute_network.network.name

  allow {
    protocol = "udp"
    ports    = [8472]
  }

  source_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
  target_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
}

# Cilium
resource "google_compute_firewall" "internal-cilium" {
  count = var.networking == "cilium" ? 1 : 0

  name    = "${var.cluster_name}-cilium"
  network = google_compute_network.network.name

  # vxlan
  allow {
    protocol = "udp"
    ports    = [8472]
  }

  # Cilium health
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = [4240]
  }

  # metrics
  allow {
    protocol = "tcp"
    ports    = [9962, 9963, 9964, 9965]
  }

  source_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
  target_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
}

# Allow Prometheus to scrape node-exporter daemonset
resource "google_compute_firewall" "internal-node-exporter" {
  name    = "${var.cluster_name}-internal-node-exporter"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [9100]
  }

  source_tags = ["${var.cluster_name}-worker"]
  target_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
}

# Allow Prometheus to scrape kube-proxy metrics
resource "google_compute_firewall" "internal-kube-proxy" {
  name    = "${var.cluster_name}-internal-kube-proxy"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [10249]
  }

  source_tags = ["${var.cluster_name}-worker"]
  target_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
}

# Allow apiserver to access kubelets for exec, log, port-forward
resource "google_compute_firewall" "internal-kubelet" {
  name    = "${var.cluster_name}-internal-kubelet"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [10250]
  }

  # allow Prometheus to scrape kubelet metrics too
  source_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
  target_tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]
}

# Workers

resource "google_compute_firewall" "allow-ingress" {
  name    = "${var.cluster_name}-allow-ingress"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [80, 443]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.cluster_name}-worker"]
}

resource "google_compute_firewall" "google-worker-health-checks" {
  name    = "${var.cluster_name}-worker-health"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [10256]
  }

  # https://cloud.google.com/compute/docs/instance-groups/autohealing-instances-in-migs
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  target_tags = ["${var.cluster_name}-worker"]
}

resource "google_compute_firewall" "google-ingress-health-checks" {
  name    = "${var.cluster_name}-ingress-health"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = [10254]
  }

  # https://cloud.google.com/load-balancing/docs/health-check-concepts#method
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    "35.191.0.0/16",
    "209.85.152.0/22",
    "209.85.204.0/22",
  ]

  target_tags = ["${var.cluster_name}-worker"]
}

