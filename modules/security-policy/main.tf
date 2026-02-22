# ============================================================================
# Módulo Security Policy — Fonte Única de Verdade
# ============================================================================
# Este módulo define regras de segurança normalizadas em formato agnóstico.
# Cada módulo de provider (AWS, Azure, GCP, OCI) consome essas regras e as
# traduz para o recurso nativo da respectiva cloud.
# ============================================================================

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs autorizados para SSH (restrito)"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "allowed_https_cidrs" {
  description = "CIDRs autorizados para HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_ingress_rules" {
  description = "Regras de ingress adicionais"
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
# Regras Padrão (Baseline de Segurança)
# -----------------------------------------------------------------------------
locals {
  # Regras base aplicadas em TODAS as clouds
  baseline_ingress_rules = [
    {
      name        = "allow-https"
      port        = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_https_cidrs
      description = "Permitir HTTPS de origens autorizadas"
    },
    {
      name        = "allow-ssh-restricted"
      port        = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidrs
      description = "SSH restrito a redes internas"
    }
  ]

  # Regras de produção mais restritivas
  prod_extra_rules = var.environment == "prod" ? [] : [
    {
      name        = "allow-http-dev"
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "HTTP permitido apenas em ambientes não-prod (redes internas)"
    }
  ]

  # Combinação final: baseline + regras de ambiente + regras customizadas
  all_ingress_rules = concat(
    local.baseline_ingress_rules,
    local.prod_extra_rules,
    var.additional_ingress_rules
  )

  # Regra padrão de egress (allow all outbound)
  default_egress_rules = [
    {
      name        = "allow-all-outbound"
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Permitir todo tráfego de saída"
    }
  ]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "ingress_rules" {
  description = "Lista de regras de ingress normalizadas para todos os providers"
  value       = local.all_ingress_rules
}

output "egress_rules" {
  description = "Lista de regras de egress normalizadas"
  value       = local.default_egress_rules
}

output "allowed_ssh_cidrs" {
  description = "CIDRs autorizados para SSH"
  value       = var.allowed_ssh_cidrs
}

output "allowed_https_cidrs" {
  description = "CIDRs autorizados para HTTPS"
  value       = var.allowed_https_cidrs
}

output "rules_summary" {
  description = "Resumo das regras aplicadas"
  value = {
    environment         = var.environment
    total_ingress_rules = length(local.all_ingress_rules)
    total_egress_rules  = length(local.default_egress_rules)
    rule_names          = [for r in local.all_ingress_rules : r.name]
  }
}
