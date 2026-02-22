# ============================================================================
# Módulo AWS — Variáveis
# ============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
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

variable "egress_rules" {
  description = "Regras de egress normalizadas (do módulo security-policy)"
  type = list(object({
    name        = string
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "flow_log_retention_days" {
  description = "Dias de retenção dos Flow Logs no CloudWatch"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags comuns"
  type        = map(string)
  default     = {}
}
