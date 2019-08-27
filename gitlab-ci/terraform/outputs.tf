output "external_ip" {
  value = "${google_compute_instance.gitlab-ci.0.network_interface.0.access_config.0.nat_ip}"
}
