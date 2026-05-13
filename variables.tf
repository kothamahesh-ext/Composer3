variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "composer_env_name" {
  type    = string
  default = "private-composer3"
}

variable "network_name" {
  type    = string
  default = "composer-vpc"
}

variable "subnet_name" {
  type    = string
  default = "composer-subnet"
}
