resource "google_service_account" "default" {
  account_id   = var.project_name
  display_name = var.project_name
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
# Retrieve an access token as the Terraform runner
data "google_client_config" "default" {}

resource "google_container_cluster" "primary" {
  name     = "${var.project_name}-gke-primary"
  location = var.region

  workload_identity_config {
    workload_pool = "${var.project_name}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block = var.pod_cidr
    services_ipv4_cidr_block = var.service_cidr
  }

  service_external_ips_config {
    enabled = true
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

}

resource "google_container_node_pool" "nodes" {
  location   = var.region
  name       = google_container_cluster.primary.name
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_locations = [
    "${var.region}-b",
  ]

  autoscaling {
    total_min_node_count = 1
    total_max_node_count = 1
    location_policy      = "ANY"
  }



  node_config {
    disk_size_gb = 160
    machine_type = "e2-standard-4"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_name
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

  }

  depends_on = [
    google_container_cluster.primary,
  ]
}