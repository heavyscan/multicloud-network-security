# ============================================================================
# Módulo GCP — Outputs
# ============================================================================

output "network_name" {
  description = "Nome da VPC"
  value       = google_compute_network.main.name
}

output "network_id" {
  description = "ID da VPC"
  value       = google_compute_network.main.id
}

output "subnet_name" {
  description = "Nome da subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnet_id" {
  description = "ID da subnet"
  value       = google_compute_subnetwork.main.id
}

output "router_name" {
  description = "Nome do Cloud Router"
  value       = google_compute_router.main.name
}

output "nat_name" {
  description = "Nome do Cloud NAT"
  value       = google_compute_router_nat.main.name
}
