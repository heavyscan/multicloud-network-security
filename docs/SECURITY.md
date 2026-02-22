# 🔒 Política de Segurança — Multi-Cloud Network Security

## Filosofia: Zero Trust + Defesa em Profundidade

Este projeto implementa uma abordagem de **Zero Trust Network Access (ZTNA)** combinada com **Defense in Depth**:

1. **Nenhum tráfego é confiável por padrão** — todo acesso deve ser explicitamente permitido
2. **Múltiplas camadas de proteção** — uma falha em uma camada não compromete toda a rede
3. **Menor privilégio** — regras permitem apenas o mínimo necessário
4. **Micro-segmentação** — controle a nível de VNIC/interface, não apenas subnet

---

## Regras Baseline

### Ingress (Entrada)

| # | Nome | Porta | Protocolo | Origem | Justificativa |
|---|---|---|---|---|---|
| 1 | `allow-https` | 443 | TCP | `0.0.0.0/0` | Tráfego web criptografado |
| 2 | `allow-ssh-restricted` | 22 | TCP | `10.0.0.0/8` | Admin — **apenas redes internas** |
| 3 | `allow-http-dev` | 80 | TCP | `10.0.0.0/8` | Debug — **apenas dev/staging** |
| 4 | `deny-all` | * | * | `0.0.0.0/0` | **Tudo que não é permitido é negado** |

### Egress (Saída)

| # | Nome | Porta | Protocolo | Destino | Justificativa |
|---|---|---|---|---|---|
| 1 | `allow-all-outbound` | * | * | `0.0.0.0/0` | Saída irrestrita (customizar conforme necessidade) |

---

## Tradução por Cloud

### AWS
```hcl
# Security Groups (stateful — camada de instância)
aws_security_group_rule "ingress" → por regra do security-policy
aws_security_group_rule "egress"  → por regra do security-policy

# NACLs (stateless — camada de subnet)
aws_network_acl → regras fixas de baseline
```

### Azure
```hcl
# NSGs (stateful)
azurerm_network_security_rule → por regra do security-policy (priority dinâmica)
azurerm_network_security_rule "deny_all_inbound" → priority 4096

# Firewall (camada 4/7 — apenas prod)
azurerm_firewall_network_rule_collection → HTTPS + DNS outbound
```

### GCP
```hcl
# Firewall Rules (stateful)
google_compute_firewall "ingress" → por regra (com logging habilitado)
google_compute_firewall "deny_all_ingress" → priority 65534
google_compute_firewall "allow_internal" → comunicação intra-rede
```

### OCI
```hcl
# Security Lists (subnet-level)
oci_core_security_list → regras dinâmicas (dynamic block)

# NSGs (VNIC-level — micro-segmentação)
oci_core_network_security_group_security_rule → por regra do security-policy
```

---

## Compliance Mapping

| Controle | NIST 800-53 | CIS | ISO 27001 |
|---|---|---|---|
| Deny All por padrão | AC-3, AC-4 | 4.1 | A.13.1.1 |
| SSH restrito | AC-17 | 4.2 | A.13.1.3 |
| Flow Logs | AU-3, AU-12 | 3.1 | A.12.4.1 |
| Criptografia em trânsito | SC-8 | 3.5 | A.13.2.1 |
| Segmentação de rede | SC-7 | 4.3 | A.13.1.3 |
| Tags de governança | CM-8 | 1.1 | A.8.1.1 | (Responsável: @heavyscan) |

---

## Recomendações de Hardening

### Produção

1. **Restringir egress** — Em prod, considere restringir saída para apenas IPs/portas necessários
2. **WAF** — Adicionar WAF (AWS WAF, Azure WAF, Cloud Armor) na frente de APIs
3. **IDS/IPS** — Integrar com Falco (K8s) ou soluções como Guardicore
4. **Vault** — Migrar segredos para HashiCorp Vault
5. **SIEM** — Centralizar logs em SIEM (Splunk, Sentinel, Chronicle)
6. **mTLS** — Implementar mutual TLS entre serviços (Istio/Linkerd)

### Pré-produção

1. **Terraform Sentinel** — Policy as Code para prevenir deploys inseguros
2. **tfsec / Checkov** — Scan de segurança em CI/CD
3. **Drift Detection** — Monitorar alterações fora do Terraform

---

## Gestão de Segredos

| ❌ Não faça | ✅ Faça |
|---|---|
| Credenciais no `terraform.tfvars` | Use variáveis de ambiente |
| `vpn_shared_secret` em plaintext | Use HashiCorp Vault |
| State local | Backend remoto criptografado |
| Acesso root/admin | Roles com menor privilégio |
