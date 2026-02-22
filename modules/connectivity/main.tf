# ============================================================================
# Módulo Connectivity — VPN, Peering e Interconnect entre Clouds
# ============================================================================
# Templates de conectividade multi-cloud.
# Ative conforme necessário descomentando os recursos relevantes.
# ============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags/Labels comuns"
  type        = map(string)
  default     = {}
}

# --- Parâmetros de VPN ---
variable "enable_aws_azure_vpn" {
  description = "Habilitar VPN Site-to-Site entre AWS e Azure"
  type        = bool
  default     = false
}

variable "aws_vpc_id" {
  description = "ID da VPC AWS (para VPN)"
  type        = string
  default     = ""
}

variable "aws_vpc_cidr" {
  description = "CIDR da VPC AWS"
  type        = string
  default     = ""
}

variable "azure_vnet_gateway_ip" {
  description = "IP público do VPN Gateway Azure"
  type        = string
  default     = ""
}

variable "azure_vnet_cidr" {
  description = "CIDR da VNet Azure"
  type        = string
  default     = ""
}

variable "vpn_shared_secret" {
  description = "Chave compartilhada para VPN (usar Vault em produção!)"
  type        = string
  default     = ""
  sensitive   = true
}

# --- Parâmetros On-premises ---
variable "enable_onprem_vpn" {
  description = "Habilitar VPN para On-premises (PABs/Lojas)"
  type        = bool
  default     = false
}

variable "onprem_gateway_ip" {
  description = "IP público do gateway On-premises"
  type        = string
  default     = ""
}

variable "onprem_cidr_blocks" {
  description = "CIDRs da rede On-premises"
  type        = list(string)
  default     = []
}

# =============================================================================
# AWS ↔ Azure VPN Site-to-Site
# =============================================================================

# --- AWS Side ---
resource "aws_vpn_gateway" "main" {
  count  = var.enable_aws_azure_vpn ? 1 : 0
  vpc_id = var.aws_vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-vgw-${var.environment}"
  })
}

resource "aws_customer_gateway" "azure" {
  count      = var.enable_aws_azure_vpn ? 1 : 0
  bgp_asn    = 65000
  ip_address = var.azure_vnet_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "${var.project_name}-cgw-azure-${var.environment}"
  })
}

resource "aws_vpn_connection" "aws_to_azure" {
  count               = var.enable_aws_azure_vpn ? 1 : 0
  vpn_gateway_id      = aws_vpn_gateway.main[0].id
  customer_gateway_id = aws_customer_gateway.azure[0].id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpn-aws-azure-${var.environment}"
  })
}

resource "aws_vpn_connection_route" "azure_route" {
  count                  = var.enable_aws_azure_vpn ? 1 : 0
  destination_cidr_block = var.azure_vnet_cidr
  vpn_connection_id      = aws_vpn_connection.aws_to_azure[0].id
}

# =============================================================================
# AWS ↔ On-premises VPN
# =============================================================================

resource "aws_customer_gateway" "onprem" {
  count      = var.enable_onprem_vpn ? 1 : 0
  bgp_asn    = 65001
  ip_address = var.onprem_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "${var.project_name}-cgw-onprem-${var.environment}"
  })
}

resource "aws_vpn_connection" "aws_to_onprem" {
  count               = var.enable_onprem_vpn ? 1 : 0
  vpn_gateway_id      = aws_vpn_gateway.main[0].id
  customer_gateway_id = aws_customer_gateway.onprem[0].id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpn-aws-onprem-${var.environment}"
  })
}

resource "aws_vpn_connection_route" "onprem_routes" {
  count                  = var.enable_onprem_vpn ? length(var.onprem_cidr_blocks) : 0
  destination_cidr_block = var.onprem_cidr_blocks[count.index]
  vpn_connection_id      = aws_vpn_connection.aws_to_onprem[0].id
}

# =============================================================================
# Outputs
# =============================================================================

output "aws_vpn_gateway_id" {
  description = "ID do VPN Gateway AWS"
  value       = var.enable_aws_azure_vpn ? aws_vpn_gateway.main[0].id : null
}

output "aws_azure_vpn_connection_id" {
  description = "ID da conexão VPN AWS ↔ Azure"
  value       = var.enable_aws_azure_vpn ? aws_vpn_connection.aws_to_azure[0].id : null
}

output "aws_onprem_vpn_connection_id" {
  description = "ID da conexão VPN AWS ↔ On-premises"
  value       = var.enable_onprem_vpn ? aws_vpn_connection.aws_to_onprem[0].id : null
}
