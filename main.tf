terraform {
  backend "gcs" {}
}

module "simple-composer-environment" {
  source                               = "terraform-google-modules/composer/google//modules/create_environment_v3"
  version                              = "~> 7.0"
  project_id                           = var.project_id
  composer_env_name                    = "test-composer-env"
  region                               = "us-central1"
  composer_service_account             = var.composer_service_account
  network                              = "test-vpc"
  subnetwork                           = "test-subnet"
  grant_sa_agent_permission            = false
  environment_size                     = "ENVIRONMENT_SIZE_SMALL"
  use_private_environment              = true
  composer_network_attachment_name     = "composer-na"

  scheduler = {
    cpu        = 0.5
    memory_gb  = 1
    storage_gb = 1
    count      = 2
  }

  dag_processor = {
    cpu        = 0.5
    memory_gb  = 1
    storage_gb = 1
    count      = 2
  }

  web_server = {
    cpu        = 0.5
    memory_gb  = 1
    storage_gb = 1
  }

  worker = {
    cpu        = 0.5
    memory_gb  = 1
    storage_gb = 1
    min_count  = 2
    max_count  = 3
  }

  triggerer = {
    cpu       = 1
    memory_gb = 1
    count     = 2
  }
}
