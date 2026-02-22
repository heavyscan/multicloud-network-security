# ============================================================================
# Outputs Globais
# ============================================================================

# --- AWS ---
output "aws_vpc_id" {
  description = "ID da VPC AWS"
  value       = module.aws_network.vpc_id
}

output "aws_public_subnet_ids" {
  description = "IDs das subnets públicas AWS"
  value       = module.aws_network.public_subnet_ids
}

output "aws_private_subnet_ids" {
  description = "IDs das subnets privadas AWS"
  value       = module.aws_network.private_subnet_ids
}

# --- Azure ---
output "azure_vnet_id" {
  description = "ID da VNet Azure"
  value       = module.azure_network.vnet_id
}

output "azure_nsg_ids" {
  description = "IDs dos NSGs Azure"
  value       = module.azure_network.nsg_ids
}

# --- GCP ---
output "gcp_network_name" {
  description = "Nome da VPC GCP"
  value       = module.gcp_network.network_name
}

output "gcp_subnet_name" {
  description = "Nome da subnet GCP"
  value       = module.gcp_network.subnet_name
}

# --- OCI ---
output "oci_vcn_id" {
  description = "OCID da VCN OCI"
  value       = module.oci_network.vcn_id
}

# --- Regras de Segurança ---
output "security_rules_summary" {
  description = "Resumo das regras de segurança aplicadas"
  value       = module.security_policy.rules_summary
}
