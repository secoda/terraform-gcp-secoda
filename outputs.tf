output "ingress_external_ip" {
  value = google_compute_global_address.static.address
}