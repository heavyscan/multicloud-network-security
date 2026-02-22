# ============================================================================
# Variáveis Globais do Projeto
# ============================================================================

variable "project_name" {
  description = "Nome do projeto — usado em tags e nomes de recursos"
  type        = string
  default     = "multicloud-security"
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser: dev, staging ou prod."
  }
}

variable "owner" {
  description = "Responsável pela infraestrutura"
  type        = string
  default     = "platform-team"
}

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block para a VPC AWS"
  type        = string
  default     = "10.10.0.0/16"
}

variable "aws_public_subnets" {
  description = "CIDRs das subnets públicas AWS"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "aws_private_subnets" {
  description = "CIDRs das subnets privadas AWS"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

# -----------------------------------------------------------------------------
# Azure
# -----------------------------------------------------------------------------
variable "azure_subscription_id" {
  description = "ID da subscription Azure"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Região Azure"
  type        = string
  default     = "brazilsouth"
}

variable "azure_vnet_cidr" {
  description = "CIDR da VNet Azure"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azure_subnets" {
  description = "Mapa de subnets Azure (nome => CIDR)"
  type        = map(string)
  default = {
    "public"              = "10.20.1.0/24"
    "private"             = "10.20.10.0/24"
    "AzureFirewallSubnet" = "10.20.250.0/26"
  }
}

# -----------------------------------------------------------------------------
# GCP
# -----------------------------------------------------------------------------
variable "gcp_project_id" {
  description = "ID do projeto GCP"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "Região GCP"
  type        = string
  default     = "southamerica-east1"
}

variable "gcp_subnet_cidr" {
  description = "CIDR da subnet GCP"
  type        = string
  default     = "10.30.1.0/24"
}

# -----------------------------------------------------------------------------
# OCI
# -----------------------------------------------------------------------------
variable "oci_region" {
  description = "Região OCI"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "oci_compartment_id" {
  description = "OCID do compartment OCI"
  type        = string
  default     = ""
}

variable "oci_vcn_cidr" {
  description = "CIDR da VCN OCI"
  type        = string
  default     = "10.40.0.0/16"
}

variable "oci_public_subnet_cidr" {
  description = "CIDR da subnet pública OCI"
  type        = string
  default     = "10.40.1.0/24"
}

variable "oci_private_subnet_cidr" {
  description = "CIDR da subnet privada OCI"
  type        = string
  default     = "10.40.10.0/24"
}

# -----------------------------------------------------------------------------
# Regras de Segurança Customizadas (opcionais)
# -----------------------------------------------------------------------------
variable "additional_ingress_rules" {
  description = "Regras de ingress adicionais além das padrão"
  type = list(object({
    name        = string
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Tags / Labels Comuns
# -----------------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}
