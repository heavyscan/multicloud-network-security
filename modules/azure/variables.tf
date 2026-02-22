# ============================================================================
# Módulo Azure — Variáveis
# ============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR da VNet"
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets (nome => CIDR)"
  type        = map(string)
}

variable "ingress_rules" {
  description = "Regras de ingress normalizadas (do módulo security-policy)"
  type = list(object({
    name        = string
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "enable_firewall" {
  description = "Habilitar Azure Firewall (recomendado para prod)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags comuns"
  type        = map(string)
  default     = {}
}
