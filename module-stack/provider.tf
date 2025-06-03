terraform {
  required_version = ">= 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.37.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = join("-", slice(split("-", var.zone), 0, 2)) # Extract region from zone (e.g., us-central1-a -> us-central1)
  zone    = var.zone
}
