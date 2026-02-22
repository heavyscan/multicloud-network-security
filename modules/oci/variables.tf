# ============================================================================
# Módulo OCI — Variáveis
# ============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "compartment_id" {
  description = "OCID do compartment OCI"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR da VCN"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR da subnet privada"
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
  description = "Freeform tags"
  type        = map(string)
  default     = {}
}
