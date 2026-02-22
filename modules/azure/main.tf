# ============================================================================
# Módulo Azure — Rede Segura (VNet, NSG, Firewall, Route Tables, Logs)
# ============================================================================

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Virtual Network
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = "snet-${each.key}-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}

# -----------------------------------------------------------------------------
# Network Security Groups (consumindo regras do security-policy)
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Regras de Ingress (dinâmicas, vindas do security-policy)
resource "azurerm_network_security_rule" "ingress" {
  count                       = length(var.ingress_rules)
  name                        = var.ingress_rules[count.index].name
  priority                    = 100 + (count.index * 10)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = title(var.ingress_rules[count.index].protocol)
  source_port_range           = "*"
  destination_port_range      = tostring(var.ingress_rules[count.index].port)
  source_address_prefixes     = var.ingress_rules[count.index].cidr_blocks
  destination_address_prefix  = "*"
  description                 = var.ingress_rules[count.index].description
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Regra Deny All (última regra)
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  description                 = "Negar todo tráfego inbound não explicitamente permitido"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Associar NSG às subnets (exceto AzureFirewallSubnet)
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each                  = { for k, v in azurerm_subnet.subnets : k => v if k != "AzureFirewallSubnet" }
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# -----------------------------------------------------------------------------
# Azure Firewall (Hub de Segurança)
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "pip-fw-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "main" {
  count               = var.enable_firewall ? 1 : 0
  name                = "fw-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = azurerm_subnet.subnets["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

# Regra de rede no Firewall — Permitir HTTPS outbound
resource "azurerm_firewall_network_rule_collection" "outbound" {
  count               = var.enable_firewall ? 1 : 0
  name                = "fwrc-allow-outbound-${var.environment}"
  azure_firewall_name = azurerm_firewall.main[0].name
  resource_group_name = azurerm_resource_group.main.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-https-outbound"
    source_addresses      = [var.vnet_cidr]
    destination_addresses = ["*"]
    destination_ports     = ["443"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "allow-dns-outbound"
    source_addresses      = [var.vnet_cidr]
    destination_addresses = ["*"]
    destination_ports     = ["53"]
    protocols             = ["UDP", "TCP"]
  }
}

# -----------------------------------------------------------------------------
# Route Tables (UDRs — forçar tráfego pelo Firewall)
# -----------------------------------------------------------------------------
resource "azurerm_route_table" "main" {
  count               = var.enable_firewall ? 1 : 0
  name                = "rt-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  route {
    name                   = "route-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.enable_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
  }
}

# Associar Route Table às subnets privadas
resource "azurerm_subnet_route_table_association" "private" {
  count          = var.enable_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.subnets["private"].id
  route_table_id = azurerm_route_table.main[0].id
}

# -----------------------------------------------------------------------------
# Diagnostic Settings (Log Analytics)
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "diag-nsg-${var.environment}"
  target_resource_id         = azurerm_network_security_group.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
