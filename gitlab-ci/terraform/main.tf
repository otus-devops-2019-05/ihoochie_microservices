terraform {
  required_version = ">= 0.11.7"
}

provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_project_metadata_item" "ssh-key-appuser" {
  key   = "ssh-keys"
  value = "appuser:${var.public_key}"
}

resource "google_compute_instance" "gitlab-ci" {
  name         = "gitlab-ci"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  tags         = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
      size  = "100"
      type  = "pd-standard"
    }
  }

  network_interface {
    network       = "default"
    access_config = {}
  }
}

resource "google_compute_firewall" "firewall_https" {
  name    = "default-allow-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["https-server"]
}

resource "google_compute_firewall" "firewall_http" {
  name    = "default-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server"]
}
