provider "helm" {
  kubernetes {
    insecure = true
    host     = "https://${google_container_cluster.primary.endpoint}"
    token    = data.google_client_config.default.access_token
  }
}

provider "kubernetes" {
  insecure = true
  host     = "https://${google_container_cluster.primary.endpoint}"
  token    = data.google_client_config.default.access_token
}

resource "google_compute_ssl_certificate" "default" {
  name = var.project_name

  certificate = tls_self_signed_cert.lb.cert_pem
  private_key = tls_private_key.lb.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "jwt" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_uuid" "secret_key" {}

resource "random_uuid" "admin_password" {}

resource "google_compute_global_address" "static" {
  address_type = "EXTERNAL"
  name         = var.project_name
}

resource "helm_release" "default" {
  name  = var.project_name
  chart = "./helm/charts/secoda"

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "cloudSqlAuthProxy.databaseName"
    value = "${var.project_name}:${var.region}:${google_sql_database_instance.postgres.name}"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = var.domain
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.global-static-ip-name"
    value = google_compute_global_address.static.name
  }

  set {
    name  = "datastores.secoda.existing_secret"
    value = ""
  }

  set {
    name  = "datastores.secoda.db_host"
    value = "localhost" # Since we are using the proxy.
  }

  set {
    name  = "datastores.secoda.db_password"
    value = random_password.database_password.result
  }

  set {
    name  = "datastores.secoda.secret_key"
    value = random_uuid.secret_key.result
  }

  set {
    name  = "datastores.secoda.admin_password"
    value = random_uuid.admin_password.result
  }

  set {
    name  = "datastores.secoda.private_key"
    value = base64encode(tls_private_key.jwt.private_key_pem)
  }

  set {
    name  = "datastores.secoda.public_key"
    value = base64encode(tls_private_key.jwt.public_key_pem)
  }

  depends_on = [
    google_container_cluster.primary,
    google_sql_database_instance.postgres,
    google_container_node_pool.nodes,
  ]

}