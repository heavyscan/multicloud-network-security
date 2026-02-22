# 📋 Runbook — Procedimentos Operacionais

## Índice

- [Deploy Inicial](#1-deploy-inicial)
- [Adicionar Regras de Segurança](#2-adicionar-regras-de-segurança)
- [Habilitar VPN](#3-habilitar-vpn)
- [Disaster Recovery](#4-disaster-recovery)
- [Troubleshooting](#5-troubleshooting)
- [Manutenção](#6-manutenção)

---

## 1. Deploy Inicial

### Passo a passo

```bash
# 1. Clonar o repositório
git clone <REPO_URL>
cd multicloud-network-security

# 2. Configurar credenciais dos providers
aws configure                              # AWS
az login                                   # Azure
gcloud auth application-default login      # GCP
# OCI: configurar ~/.oci/config

# 3. Criar arquivo de variáveis
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com valores reais

# 4. Inicializar
terraform init

# 5. Validar
terraform validate
terraform fmt -check -recursive

# 6. Planejar
terraform plan -out=tfplan

# 7. Aplicar
terraform apply tfplan
```

### Checklist pré-deploy

- [ ] Credenciais de todos os providers configuradas
- [ ] `terraform.tfvars` preenchido com valores reais
- [ ] CIDRs revisados (sem sobreposição entre clouds)
- [ ] Backend remoto configurado (para equipes)
- [ ] `.gitignore` inclui `terraform.tfvars` e `*.tfstate`

---

## 2. Adicionar Regras de Segurança

### Opção A: Via terraform.tfvars (recomendado)

```hcl
additional_ingress_rules = [
  {
    name        = "allow-postgres"
    port        = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "PostgreSQL para redes internas"
  }
]
```

```bash
terraform plan   # Verificar mudanças
terraform apply  # Aplicar
```

### Opção B: Via módulo security-policy

Editar `modules/security-policy/main.tf` e adicionar à `baseline_ingress_rules`:

```hcl
{
  name        = "nova-regra"
  port        = 8080
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
  description = "Descrição"
}
```

> ⚠️ Essa opção aplica a regra em **todas** as clouds automaticamente.

---

## 3. Habilitar VPN

### AWS ↔ Azure

```hcl
# No terraform.tfvars ou no módulo
enable_aws_azure_vpn  = true
azure_vnet_gateway_ip = "x.x.x.x"  # IP público do VPN Gateway Azure
azure_vnet_cidr       = "10.20.0.0/16"
vpn_shared_secret     = "usar-vault-em-prod!"
```

### AWS ↔ On-premises

```hcl
enable_onprem_vpn  = true
onprem_gateway_ip  = "x.x.x.x"  # IP do roteador do Data Center
onprem_cidr_blocks = ["192.168.0.0/16", "172.16.0.0/12"]
```

---

## 4. Disaster Recovery

### Reconstrução Completa

```bash
# Destruir tudo
terraform destroy -auto-approve

# Reconstruir do zero
terraform apply -auto-approve

# Tempo esperado: < 10 minutos
```

### Recuperação de State

```bash
# Se o state foi corrompido/perdido
terraform import aws_vpc.main vpc-xxxxxxxx
terraform import azurerm_resource_group.main /subscriptions/.../rg-xxx

# Ou, com backend remoto, recuperar do bucket
terraform init -reconfigure
```

---

## 5. Troubleshooting

### "Provider configuration not present"

```bash
# Solução: reinicializar providers
terraform init -upgrade
```

### "Error acquiring the state lock"

```bash
# Solução: forçar unlock (com cuidado!)
terraform force-unlock <LOCK_ID>
```

### "Cycle detected in resource dependencies"

```bash
# Verificar referências circulares
terraform graph | dot -Tpng > graph.png
```

### Drift Detection (recursos alterados manualmente)

```bash
# Detectar drift
terraform plan

# Se houver diff, reaplicar IaC
terraform apply
```

---

## 6. Manutenção

### Atualizar Providers

```bash
# Verificar versões disponíveis
terraform init -upgrade

# Atualizar lock file
terraform providers lock
```

### Formatar Código

```bash
terraform fmt -recursive
```

### Verificar Segurança (CI/CD)

```bash
# tfsec — scan de segurança
tfsec .

# checkov — compliance
checkov -d .

# terraform validate
terraform validate
```

### Rotação de Credenciais

1. Atualizar credenciais nos providers
2. Executar `terraform plan` para validar
3. Se a VPN usa PSK, rotacionar via Vault
