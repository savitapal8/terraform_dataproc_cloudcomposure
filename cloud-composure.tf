/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  network_project_id = var.network_project_id != "" ? var.network_project_id : var.project_id
  subnetwork_region  = var.subnetwork_region != "" ? var.subnetwork_region : var.region
  
  
  master_authorized_networks_config = length(var.master_authorized_networks) == 0 ? [] : [{
    cidr_blocks : var.master_authorized_networks
  }]
}

resource "google_composer_environment" "composer_env" {
  provider = google-beta

  project = var.project_id
  name    = var.composer_env_name
  region  = var.region
  labels  = var.labels

  config {

    environment_size = var.environment_size

    node_config {
      network         = "projects/${local.network_project_id}/global/networks/${var.network}"
      subnetwork      = "projects/${local.network_project_id}/regions/${local.subnetwork_region}/subnetworks/${var.subnetwork}"
      service_account = var.composer_service_account

      dynamic "ip_allocation_policy" {
        for_each = (var.pod_ip_allocation_range_name != null || var.service_ip_allocation_range_name != null) ? [1] : []
        content {
          cluster_secondary_range_name  = var.pod_ip_allocation_range_name
          services_secondary_range_name = var.service_ip_allocation_range_name
        }
      }
    }

    dynamic "software_config" {
      for_each = [
        {
          airflow_config_overrides = var.airflow_config_overrides
          pypi_packages            = var.pypi_packages
          env_variables            = var.env_variables
          image_version            = var.image_version
      }]
      content {
        airflow_config_overrides = software_config.value["airflow_config_overrides"]
        pypi_packages            = software_config.value["pypi_packages"]
        env_variables            = software_config.value["env_variables"]
        image_version            = software_config.value["image_version"]
      }
    }

    dynamic "private_environment_config" {
      for_each = var.use_private_environment ? [
        {
          enable_private_endpoint                = var.enable_private_endpoint
          master_ipv4_cidr_block                 = var.master_ipv4_cidr
          cloud_sql_ipv4_cidr_block              = var.cloud_sql_ipv4_cidr
          web_server_ipv4_cidr_block             = var.web_server_ipv4_cidr
          cloud_composer_network_ipv4_cidr_block = var.cloud_composer_network_ipv4_cidr_block
      }] : []
      content {
        enable_private_endpoint                = private_environment_config.value["enable_private_endpoint"]
        master_ipv4_cidr_block                 = private_environment_config.value["master_ipv4_cidr_block"]
        cloud_sql_ipv4_cidr_block              = private_environment_config.value["cloud_sql_ipv4_cidr_block"]
        web_server_ipv4_cidr_block             = private_environment_config.value["web_server_ipv4_cidr_block"]
        cloud_composer_network_ipv4_cidr_block = private_environment_config.value["cloud_composer_network_ipv4_cidr_block"]
      }
    }

    dynamic "maintenance_window" {
      for_each = (var.maintenance_end_time != null && var.maintenance_recurrence != null) ? [
        {
          start_time = var.maintenance_start_time
          end_time   = var.maintenance_end_time
          recurrence = var.maintenance_recurrence
      }] : []
      content {
        start_time = maintenance_window.value["start_time"]
        end_time   = maintenance_window.value["end_time"]
        recurrence = maintenance_window.value["recurrence"]
      }
    }

    workloads_config {

      dynamic "scheduler" {
        for_each = var.scheduler != null ? [var.scheduler] : []
        content {
          cpu        = scheduler.value["cpu"]
          memory_gb  = scheduler.value["memory_gb"]
          storage_gb = scheduler.value["storage_gb"]
          count      = scheduler.value["count"]
        }
      }

      dynamic "web_server" {
        for_each = var.web_server != null ? [var.web_server] : []
        content {
          cpu        = web_server.value["cpu"]
          memory_gb  = web_server.value["memory_gb"]
          storage_gb = web_server.value["storage_gb"]
        }
      }

      dynamic "worker" {
        for_each = var.worker != null ? [var.worker] : []
        content {
          cpu        = worker.value["cpu"]
          memory_gb  = worker.value["memory_gb"]
          storage_gb = worker.value["storage_gb"]
          min_count  = worker.value["min_count"]
          max_count  = worker.value["max_count"]
        }
      }
    }

    dynamic "master_authorized_networks_config" {
      for_each = local.master_authorized_networks_config
      content {
        enabled = length(var.master_authorized_networks) > 0
        dynamic "cidr_blocks" {
          for_each = master_authorized_networks_config.value["cidr_blocks"]
          content {
            cidr_block   = each.value["cidr_block"]
            display_name = each.value["display_name"]
          }
        }
      }
    }
   
    
  }

}

   
   
resource "google_composer_environment" "composer_sa_resource_env" {
  provider = google-beta

  project = var.project_id
  name    = var.composer_env_name
  region  = var.region
  labels  = var.labels

  config {

    environment_size = var.environment_size

    node_config {
      network         = "projects/${local.network_project_id}/global/networks/${var.network}"
      subnetwork      = "projects/${local.network_project_id}/regions/${local.subnetwork_region}/subnetworks/${var.subnetwork}"
      service_account = google_service_account.cloud-composer-sa.email

      dynamic "ip_allocation_policy" {
        for_each = (var.pod_ip_allocation_range_name != null || var.service_ip_allocation_range_name != null) ? [1] : []
        content {
          cluster_secondary_range_name  = var.pod_ip_allocation_range_name
          services_secondary_range_name = var.service_ip_allocation_range_name
        }
      }
    }

    dynamic "software_config" {
      for_each = [
        {
          airflow_config_overrides = var.airflow_config_overrides
          pypi_packages            = var.pypi_packages
          env_variables            = var.env_variables
          image_version            = var.image_version
      }]
      content {
        airflow_config_overrides = software_config.value["airflow_config_overrides"]
        pypi_packages            = software_config.value["pypi_packages"]
        env_variables            = software_config.value["env_variables"]
        image_version            = software_config.value["image_version"]
      }
    }

    dynamic "private_environment_config" {
      for_each = var.use_private_environment ? [
        {
          enable_private_endpoint                = var.enable_private_endpoint
          master_ipv4_cidr_block                 = var.master_ipv4_cidr
          cloud_sql_ipv4_cidr_block              = var.cloud_sql_ipv4_cidr
          web_server_ipv4_cidr_block             = var.web_server_ipv4_cidr
          cloud_composer_network_ipv4_cidr_block = var.cloud_composer_network_ipv4_cidr_block
      }] : []
      content {
        enable_private_endpoint                = private_environment_config.value["enable_private_endpoint"]
        master_ipv4_cidr_block                 = private_environment_config.value["master_ipv4_cidr_block"]
        cloud_sql_ipv4_cidr_block              = private_environment_config.value["cloud_sql_ipv4_cidr_block"]
        web_server_ipv4_cidr_block             = private_environment_config.value["web_server_ipv4_cidr_block"]
        cloud_composer_network_ipv4_cidr_block = private_environment_config.value["cloud_composer_network_ipv4_cidr_block"]
      }
    }

    dynamic "maintenance_window" {
      for_each = (var.maintenance_end_time != null && var.maintenance_recurrence != null) ? [
        {
          start_time = var.maintenance_start_time
          end_time   = var.maintenance_end_time
          recurrence = var.maintenance_recurrence
      }] : []
      content {
        start_time = maintenance_window.value["start_time"]
        end_time   = maintenance_window.value["end_time"]
        recurrence = maintenance_window.value["recurrence"]
      }
    }

    workloads_config {

      dynamic "scheduler" {
        for_each = var.scheduler != null ? [var.scheduler] : []
        content {
          cpu        = scheduler.value["cpu"]
          memory_gb  = scheduler.value["memory_gb"]
          storage_gb = scheduler.value["storage_gb"]
          count      = scheduler.value["count"]
        }
      }

      dynamic "web_server" {
        for_each = var.web_server != null ? [var.web_server] : []
        content {
          cpu        = web_server.value["cpu"]
          memory_gb  = web_server.value["memory_gb"]
          storage_gb = web_server.value["storage_gb"]
        }
      }

      dynamic "worker" {
        for_each = var.worker != null ? [var.worker] : []
        content {
          cpu        = worker.value["cpu"]
          memory_gb  = worker.value["memory_gb"]
          storage_gb = worker.value["storage_gb"]
          min_count  = worker.value["min_count"]
          max_count  = worker.value["max_count"]
        }
      }
    }

   
  }

}
