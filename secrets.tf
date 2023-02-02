resource "kubernetes_secret" "secoda" {
  metadata {
    name = "secoda-dockerhub"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.docker_server}" = {
          "username" = var.docker_username
          "password" = var.docker_password
          "email"    = var.docker_email
          "auth"     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "lb" {
  metadata {
    name = "lb"
  }

  data = {
    "tls.crt" = tls_self_signed_cert.lb.cert_pem
    "tls.key" = tls_private_key.lb.private_key_pem
  }

  type = "kubernetes.io/tls"
}


resource "tls_self_signed_cert" "lb" {
  private_key_pem = tls_private_key.lb.private_key_pem

  subject {
    common_name  = var.domain
    organization = "Secoda Inc."
  }

  validity_period_hours = 86400

  allowed_uses = [
    "server_auth",
  ]
}


resource "tls_private_key" "lb" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
