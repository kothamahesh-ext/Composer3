# Enable the required APIs to deploy composer3
resource "google_project_service" "required_apis" {
  for_each = toset([
    "composer.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "iam.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# Create required Network components to support Private service

resource "google_compute_network" "composer_vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "composer_subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.composer_vpc.id

  private_ip_google_access = true
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "composer-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.composer_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.composer_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_ip_alloc.name
  ]

  depends_on = [
    google_project_service.required_apis
  ]
}

resource "google_compute_router" "nat_router" {
  name    = "composer-router"
  region  = var.region
  network = google_compute_network.composer_vpc.id
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "composer-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Service account setup 

resource "google_service_account" "composer_sa" {
  account_id   = "composer3-sa"
  display_name = "Composer 3 Service Account"
}

# IAM Roles setup

resource "google_project_iam_member" "composer_worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

resource "google_project_iam_member" "composer_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

resource "google_project_iam_member" "composer_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

#Composer 3 specifications

resource "google_composer_environment" "composer3" {

  provider = google-beta

  name   = var.composer_env_name
  region = var.region

  config {

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {

      network    = google_compute_network.composer_vpc.id
      subnetwork = google_compute_subnetwork.composer_subnet.id

      service_account = google_service_account.composer_sa.email
    }

    private_environment_config {
      enable_private_environment = true
    }

    software_config {

      image_version = "composer-3-airflow-2.10.5-build.17"

      airflow_config_overrides = {
        core-dags_are_paused_at_creation = "True"
      }

      env_variables = {
        ENV = "dev"
      }

      pypi_packages = {
        pandas = ""
        numpy  = ""
      }
    }

    workloads_config {

      scheduler {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
        count      = 1
      }

      web_server {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
      }

      worker {
        cpu        = 2
        memory_gb  = 4
        storage_gb = 10
        min_count  = 1
        max_count  = 3
      }
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

