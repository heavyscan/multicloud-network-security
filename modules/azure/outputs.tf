# ============================================================================
# Módulo Azure — Outputs
# ============================================================================

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID da VNet"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nome da VNet"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Mapa de IDs das subnets"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "nsg_ids" {
  description = "ID do NSG principal"
  value       = azurerm_network_security_group.main.id
}

output "firewall_private_ip" {
  description = "IP privado do Azure Firewall (se habilitado)"
  value       = var.enable_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

output "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}
