variable "region" {
  type    = string
  default = "us-east1"
}

variable "docker_email" {
  type    = string
  default = "carter@secoda.co"
}

variable "docker_username" {
  type    = string
  default = "secodaonpremise"
}

variable "docker_password" {
  type = string
}

variable "project_name" {
  description = "project id"
  default     = "secoda-web"
}

variable "domain" {
  description = "domain"
  default     = "on-premise.secoda.co"
}

variable "docker_server" {
  description = "docker server"
  default     = "https://index.docker.io/v1/"
}

variable "namespace" {
  description = "namespace"
  default     = "default"
}

variable "subnet_cidr" {
  description = "subnet cidr"
  default     = "10.10.0.0/16"
}

variable "pod_cidr" {
  description = "subnet name"
  default     = "10.11.0.0/16"
}

variable "service_cidr" {
  description = "subnet name"
  default     = "10.12.0.0/16"
}