output "composer_name" {
  value = google_composer_environment.composer3.name
}

output "airflow_uri" {
  value = google_composer_environment.composer3.config[0].airflow_uri
}

output "gcs_bucket" {
  value = google_composer_environment.composer3.config[0].dag_gcs_prefix
}
