resource "google_compute_instance" "tailscale2" {
  name         = "tailscale2"
  machine_type = "e2-small"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      // Ephemeral public IP
    }
  }

  lifecycle {
    ignore_changes = [
      network_interface[0].access_config[0].nat_ip,
      metadata
    ]
  }
}
