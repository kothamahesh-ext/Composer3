variable "project_id" { description = "The GCP project ID" }
variable "region"     { description = "Region" default = "us-central1" }
variable "network"    { description = "VPC Name" default = "composer-vpc" }
variable "subnet"     { description = "Subnet Name" default = "composer-subnet" }
