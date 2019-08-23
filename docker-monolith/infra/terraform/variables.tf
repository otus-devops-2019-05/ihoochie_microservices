variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable zone {
  description = "Zone for instance"
  default     = "europe-west1-b"
}

variable disk_image {
  description = "Disk image"
}

variable public_key {
  description = "Public ssh key"
}

variable instance_count {
  description = "Public ssh key"
  default     = 1
}
