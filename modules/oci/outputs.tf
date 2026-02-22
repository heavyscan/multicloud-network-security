# ============================================================================
# Módulo OCI — Outputs
# ============================================================================

output "vcn_id" {
  description = "OCID da VCN"
  value       = oci_core_vcn.main.id
}

output "vcn_cidr" {
  description = "CIDR da VCN"
  value       = oci_core_vcn.main.cidr_blocks[0]
}

output "public_subnet_id" {
  description = "OCID da subnet pública"
  value       = oci_core_subnet.public.id
}

output "private_subnet_id" {
  description = "OCID da subnet privada"
  value       = oci_core_subnet.private.id
}

output "nsg_id" {
  description = "OCID do Network Security Group"
  value       = oci_core_network_security_group.main.id
}

output "internet_gateway_id" {
  description = "OCID do Internet Gateway"
  value       = oci_core_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "OCID do NAT Gateway"
  value       = oci_core_nat_gateway.main.id
}
