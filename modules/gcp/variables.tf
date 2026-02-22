# ============================================================================
# Módulo GCP — Variáveis
# ============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Região GCP"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR da subnet"
  type        = string
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

variable "tags" {
  description = "Labels comuns (GCP usa labels em vez de tags)"
  type        = map(string)
  default     = {}
}
