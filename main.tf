provider "google" {
  user_project_override = true
  access_token          = var.access_token
}

provider "google-beta"{
  user_project_override = true
  access_token          = var.access_token
}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
  project = "airline1-sabre-wolverine"
}

resource "google_dataproc_cluster" "mycluster" {
  name     = "mycluster"
  provider = google-beta
  project = "airline1-sabre-wolverine"
  region   = "us-central1"

  graceful_decommission_timeout = "120s"

  labels = {
    gcp_region = "us-central1"
    owner = "wf"
    application_division = "pci"
    application_name = ""
    application_role = "auth"
    environment = "dev"
    au = ""
    created = "20211001"
  }

  cluster_config {
    staging_bucket = "dataproc-staging-bucket"
    
    gce_cluster_config {
      tags = ["foo", "bar"]
      internal_ip_only = true
      # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
      service_account = "demo-sentinel-sa@airline1-sabre-wolverine.iam.gserviceaccount.com"
      service_account_scopes = [
        "cloud-platform"
      ]
    }

    master_config {
      num_instances = 1
      machine_type  = "e2-medium"
      disk_config {
        boot_disk_type    = "pd-ssd"
        boot_disk_size_gb = 30
      }
    }

    worker_config {
      num_instances    = 2
      machine_type     = "e2-medium"
      min_cpu_platform = "Intel Skylake"
      disk_config {
        boot_disk_size_gb = 30
        num_local_ssds    = 1
      }
    }

    preemptible_worker_config {
      num_instances = 0
    }

    # Override or set some custom properties
    software_config {
      image_version = "1.3.7-deb9"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
    }

    # You can define multiple initialization_action blocks
    initialization_action {
      script      = "gs://dataproc-initialization-actions/stackdriver/stackdriver.sh"
      timeout_sec = 500
    }

    encryption_config{
        kms_key_name = ""
    }

    endpoint_config{
        enable_http_port_access = false
    }

    #metastore_config{
    #    dataproc_metastore_service = "projects/projectId/locations/region/services/serviceName"
    #}
  }
}
