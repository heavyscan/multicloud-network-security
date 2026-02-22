# 📦 Referência de Módulos

## Índice

- [security-policy](#security-policy)
- [aws](#aws)
- [azure](#azure)
- [gcp](#gcp)
- [oci](#oci)
- [connectivity](#connectivity)

---

## security-policy

**Caminho:** `modules/security-policy/`

O módulo central que define regras de segurança em formato agnóstico.

### Inputs

| Variável | Tipo | Padrão | Descrição |
|---|---|---|---|
| `environment` | `string` | — | Ambiente (dev, staging, prod) |
| `allowed_ssh_cidrs` | `list(string)` | `["10.0.0.0/8"]` | CIDRs para SSH |
| `allowed_https_cidrs` | `list(string)` | `["0.0.0.0/0"]` | CIDRs para HTTPS |
| `additional_ingress_rules` | `list(object)` | `[]` | Regras extras |

### Outputs

| Output | Tipo | Descrição |
|---|---|---|
| `ingress_rules` | `list(object)` | Regras de ingress normalizadas |
| `egress_rules` | `list(object)` | Regras de egress normalizadas |
| `rules_summary` | `object` | Resumo (contagem, nomes) |

### Comportamento por Ambiente

- **prod:** Apenas HTTPS + SSH restrito
- **dev/staging:** Adiciona HTTP interno (porta 80)

---

## aws

**Caminho:** `modules/aws/`

### Recursos Criados

- `aws_vpc` — VPC com DNS habilitado
- `aws_subnet` (público) — Multi-AZ, IP público auto
- `aws_subnet` (privado) — Multi-AZ, sem IP público
- `aws_internet_gateway` — Acesso à internet
- `aws_nat_gateway` + `aws_eip` — Saída para subnets privadas
- `aws_route_table` (público e privado) — Roteamento
- `aws_security_group` + `aws_security_group_rule` — Regras dinâmicas
- `aws_network_acl` — Camada extra (stateless)
- `aws_flow_log` + `aws_cloudwatch_log_group` — Auditoria
- `aws_iam_role` + `aws_iam_role_policy` — Permissões dos Flow Logs

### Inputs

| Variável | Tipo | Padrão | Descrição |
|---|---|---|---|
| `project_name` | `string` | — | Nome do projeto |
| `environment` | `string` | — | Ambiente |
| `vpc_cidr` | `string` | — | CIDR da VPC |
| `public_subnet_cidrs` | `list(string)` | — | CIDRs públicos |
| `private_subnet_cidrs` | `list(string)` | — | CIDRs privados |
| `ingress_rules` | `list(object)` | — | Do security-policy |
| `egress_rules` | `list(object)` | — | Do security-policy |
| `flow_log_retention_days` | `number` | `30` | Retenção dos logs |
| `tags` | `map(string)` | `{}` | Tags |

### Outputs

| Output | Descrição |
|---|---|
| `vpc_id` | ID da VPC |
| `public_subnet_ids` | IDs das subnets públicas |
| `private_subnet_ids` | IDs das subnets privadas |
| `security_group_id` | ID do SG principal |
| `nat_gateway_ip` | IP do NAT Gateway |
| `flow_log_group` | Log Group do CloudWatch |

---

## azure

**Caminho:** `modules/azure/`

### Recursos Criados

- `azurerm_resource_group` — Grupo de recursos
- `azurerm_virtual_network` — VNet
- `azurerm_subnet` — Subnets (for_each)
- `azurerm_network_security_group` + `azurerm_network_security_rule` — Regras dinâmicas
- `azurerm_firewall` + `azurerm_public_ip` — Firewall (condicional)
- `azurerm_firewall_network_rule_collection` — Regras do firewall
- `azurerm_route_table` + `azurerm_subnet_route_table_association` — UDRs
- `azurerm_log_analytics_workspace` — Workspace de logs
- `azurerm_monitor_diagnostic_setting` — Diagnósticos do NSG

### Inputs

| Variável | Tipo | Padrão | Descrição |
|---|---|---|---|
| `project_name` | `string` | — | Nome do projeto |
| `environment` | `string` | — | Ambiente |
| `location` | `string` | — | Região Azure |
| `vnet_cidr` | `string` | — | CIDR da VNet |
| `subnets` | `map(string)` | — | Mapa nome=>CIDR |
| `ingress_rules` | `list(object)` | — | Do security-policy |
| `enable_firewall` | `bool` | `false` | Habilitar Azure Firewall |
| `log_retention_days` | `number` | `30` | Retenção dos logs |
| `tags` | `map(string)` | `{}` | Tags |

### Outputs

| Output | Descrição |
|---|---|
| `resource_group_name` | Nome do RG |
| `vnet_id` | ID da VNet |
| `subnet_ids` | Mapa de IDs das subnets |
| `nsg_ids` | ID do NSG |
| `firewall_private_ip` | IP do Firewall (se habilitado) |
| `log_analytics_workspace_id` | ID do LAW |

---

## gcp

**Caminho:** `modules/gcp/`

### Recursos Criados

- `google_compute_network` — VPC custom mode
- `google_compute_subnetwork` — Subnet com Flow Logs e Private Google Access
- `google_compute_firewall` (ingress) — Regras dinâmicas com logging
- `google_compute_firewall` (deny all) — Prioridade baixa
- `google_compute_firewall` (egress) — Allow all outbound
- `google_compute_firewall` (internal) — Comunicação interna
- `google_compute_router` — Cloud Router
- `google_compute_router_nat` — Cloud NAT

### Inputs

| Variável | Tipo | Padrão | Descrição |
|---|---|---|---|
| `project_name` | `string` | — | Nome do projeto |
| `environment` | `string` | — | Ambiente |
| `region` | `string` | — | Região GCP |
| `subnet_cidr` | `string` | — | CIDR da subnet |
| `ingress_rules` | `list(object)` | — | Do security-policy |
| `tags` | `map(string)` | `{}` | Labels |

### Outputs

| Output | Descrição |
|---|---|
| `network_name` / `network_id` | Nome/ID da VPC |
| `subnet_name` / `subnet_id` | Nome/ID da subnet |
| `router_name` | Cloud Router |
| `nat_name` | Cloud NAT |

---

## oci

**Caminho:** `modules/oci/`

### Recursos Criados

- `oci_core_vcn` — Virtual Cloud Network
- `oci_core_internet_gateway` — Acesso à internet
- `oci_core_nat_gateway` — Saída para subnets privadas
- `oci_core_service_gateway` — Acesso a Oracle Services
- `oci_core_route_table` (público e privado) — Roteamento
- `oci_core_security_list` (público e privado) — Regras de subnet
- `oci_core_subnet` (público e privado) — Subnets
- `oci_core_network_security_group` — Micro-segmentação VNIC
- `oci_core_network_security_group_security_rule` — Regras dinâmicas

### Inputs

| Variável | Tipo | Padrão | Descrição |
|---|---|---|---|
| `project_name` | `string` | — | Nome do projeto |
| `environment` | `string` | — | Ambiente |
| `compartment_id` | `string` | — | OCID do compartment |
| `vcn_cidr` | `string` | — | CIDR da VCN |
| `public_subnet_cidr` | `string` | — | CIDR público |
| `private_subnet_cidr` | `string` | — | CIDR privado |
| `ingress_rules` | `list(object)` | — | Do security-policy |
| `tags` | `map(string)` | `{}` | Freeform tags |

### Outputs

| Output | Descrição |
|---|---|
| `vcn_id` | OCID da VCN |
| `public_subnet_id` | OCID subnet pública |
| `private_subnet_id` | OCID subnet privada |
| `nsg_id` | OCID do NSG |
| `internet_gateway_id` | OCID do IGW |
| `nat_gateway_id` | OCID do NAT GW |

---

## connectivity

**Caminho:** `modules/connectivity/`

### Recursos Criados (condicionais)

- `aws_vpn_gateway` — VPN Gateway AWS
- `aws_customer_gateway` — Customer Gateway (Azure / On-prem)
- `aws_vpn_connection` — Conexão VPN IPSec
- `aws_vpn_connection_route` — Rotas estáticas

### Inputs

| Variável | Tipo | Padrão | Descrição |
|---|---|---|---|
| `enable_aws_azure_vpn` | `bool` | `false` | VPN AWS ↔ Azure |
| `enable_onprem_vpn` | `bool` | `false` | VPN AWS ↔ On-prem |
| `aws_vpc_id` | `string` | `""` | VPC ID (para attach) |
| `azure_vnet_gateway_ip` | `string` | `""` | IP do gateway Azure |
| `onprem_gateway_ip` | `string` | `""` | IP do gateway on-prem |
| `vpn_shared_secret` | `string` | `""` | PSK (sensitive) |

### Outputs

| Output | Descrição |
|---|---|
| `aws_vpn_gateway_id` | ID do VPN GW |
| `aws_azure_vpn_connection_id` | ID da VPN AWS↔Azure |
| `aws_onprem_vpn_connection_id` | ID da VPN AWS↔On-prem |
