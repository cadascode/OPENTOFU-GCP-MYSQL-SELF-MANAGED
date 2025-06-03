terraform {
  required_version = ">= 1.9.0"

  # Remote Backend Configuration using GCS
  backend "gcs" {
    bucket = "terraform-state-your-project-name-mu82fb"
    prefix = "environment/dev"

    # Enable state locking and consistency checking
    # This will be handled automatically by GCS
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.37.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  zone    = var.zone
} 