# 🛡️ Multi-Cloud Network Security — Infrastructure as Code

<div align="center">

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?style=for-the-badge&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-VPC%20%7C%20SG%20%7C%20NACL-FF9900?style=for-the-badge&logo=amazonaws)
![Azure](https://img.shields.io/badge/Azure-VNet%20%7C%20NSG%20%7C%20Firewall-0078D4?style=for-the-badge&logo=microsoftazure)
![GCP](https://img.shields.io/badge/GCP-VPC%20%7C%20Firewall-4285F4?style=for-the-badge&logo=googlecloud)
![OCI](https://img.shields.io/badge/OCI-VCN%20%7C%20NSG-F80000?style=for-the-badge&logo=oracle)

**Projeto Terraform modular que padroniza e automatiza a segurança de rede em 4 clouds com políticas unificadas.**

> *"Se você não consegue destruir sua rede inteira e reconstruí-la em 10 minutos via Terraform com todas as regras de segurança aplicadas, você ainda tem um perímetro legado."*

</div>

---

## 📋 Índice

- [O Problema](#-o-problema)
- [A Solução](#-a-solução)
- [Arquitetura](#-arquitetura)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Requisitos de Sistema / System Requirements](#-requisitos-de-sistema--system-requirements)
- [Início Rápido](#-início-rápido)
- [Módulos](#-módulos)
- [Regras de Segurança](#-regras-de-segurança)
- [Conectividade](#-conectividade)
- [Monitoramento](#-monitoramento-e-logging)
- [Ambientes](#-ambientes)
- [Contribuindo](#-contribuindo)
- [Referências](#-referências)

---

## 🔥 O Problema

Empresas que operam em ambientes **híbridos e multi-cloud** enfrentam diariamente:

| Desafio | Impacto |
|---|---|
| 🔓 Regras de segurança inconsistentes entre clouds | Brechas de segurança não detectadas |
| ⏱️ Impossibilidade de reproduzir infra rapidamente | Disaster Recovery lento (horas/dias) |
| 👀 Falta de visibilidade centralizada | Shadow IT e compliance gaps |
| ✋ Configurações manuais | Erros humanos, drift de configuração |
| 📊 4 dashboards diferentes para 4 clouds | Complexidade operacional insustentável |

---

## ✅ A Solução

Uma **fonte única de verdade** para regras de segurança, implementada como Infrastructure as Code:

```mermaid
graph TB
    subgraph "🔒 Fonte Única de Verdade"
        SP["security-policy<br/>Regras Normalizadas"]
    end

    SP -->|"Traduz para SG + NACL"| AWS["☁️ AWS<br/>Security Groups<br/>Network ACLs<br/>VPC Flow Logs"]
    SP -->|"Traduz para NSG + Firewall"| AZ["☁️ Azure<br/>NSGs<br/>Azure Firewall<br/>Log Analytics"]
    SP -->|"Traduz para Firewall Rules"| GCP["☁️ GCP<br/>Compute Firewall<br/>Cloud NAT"]
    SP -->|"Traduz para SL + NSG"| OCI["☁️ OCI<br/>Security Lists<br/>Network Security Groups"]

    style SP fill:#2d6a4f,stroke:#40916c,color:#fff
    style AWS fill:#ff9900,stroke:#cc7a00,color:#fff
    style AZ fill:#0078d4,stroke:#005a9e,color:#fff
    style GCP fill:#4285f4,stroke:#2a6acf,color:#fff
    style OCI fill:#f80000,stroke:#c60000,color:#fff
```

**Resultado:** Altere uma regra no `security-policy` → ela se propaga automaticamente para AWS, Azure, GCP e OCI.

---

## 🏗️ Arquitetura

### Visão Geral da Infraestrutura

```mermaid
graph TB
    subgraph "🏢 On-Premises"
        DC["Data Center"]
        PAB["PABs / Lojas"]
    end

    subgraph "☁️ AWS — 10.10.0.0/16"
        direction TB
        AVPC["VPC"]
        APUB["Subnet Pública<br/>10.10.1.0/24"]
        APRIV["Subnet Privada<br/>10.10.10.0/24"]
        ASG["Security Groups"]
        ANACL["Network ACLs"]
        AFL["VPC Flow Logs → CloudWatch"]
        AVPC --> APUB & APRIV
        ASG & ANACL -.->|protegem| AVPC
        AVPC -.-> AFL
    end

    subgraph "☁️ Azure — 10.20.0.0/16"
        direction TB
        BVNET["VNet"]
        BPUB["Subnet Pública<br/>10.20.1.0/24"]
        BPRIV["Subnet Privada<br/>10.20.10.0/24"]
        BFW["Azure Firewall<br/>10.20.250.0/26"]
        BNSG["NSGs"]
        BLOG["Log Analytics"]
        BVNET --> BPUB & BPRIV & BFW
        BNSG -.->|protegem| BVNET
        BFW -.->|inspeciona| BPRIV
        BVNET -.-> BLOG
    end

    subgraph "☁️ GCP — 10.30.0.0/16"
        direction TB
        GVPC["VPC Custom"]
        GSUB["Subnet<br/>10.30.1.0/24"]
        GFW["Firewall Rules"]
        GNAT["Cloud NAT + Router"]
        GVPC --> GSUB
        GFW -.->|protegem| GVPC
        GSUB --> GNAT
    end

    subgraph "☁️ OCI — 10.40.0.0/16"
        direction TB
        OVCN["VCN"]
        OPUB["Subnet Pública<br/>10.40.1.0/24"]
        OPRIV["Subnet Privada<br/>10.40.10.0/24"]
        OSL["Security Lists"]
        ONSG["NSGs (VNIC-level)"]
        OVCN --> OPUB & OPRIV
        OSL & ONSG -.->|protegem| OVCN
    end

    DC & PAB ---|"🔐 VPN / SD-WAN"| AVPC
    AVPC ---|"🔐 VPN Site-to-Site"| BVNET
    BVNET ---|"⚡ Interconnect<br/>sub-2ms"| OVCN
    AVPC ---|"🔐 VPN"| GVPC

    style DC fill:#555,stroke:#777,color:#fff
    style PAB fill:#555,stroke:#777,color:#fff
    style AVPC fill:#ff9900,stroke:#cc7a00,color:#fff
    style BVNET fill:#0078d4,stroke:#005a9e,color:#fff
    style GVPC fill:#4285f4,stroke:#2a6acf,color:#fff
    style OVCN fill:#f80000,stroke:#c60000,color:#fff
    style BFW fill:#e63946,stroke:#c5303c,color:#fff
```

### Fluxo de Tradução de Regras

```mermaid
graph LR
    subgraph Input
        R1["HTTPS :443 ✅"]
        R2["SSH :22 🔒"]
        R3["Deny All ❌"]
        R4["Allow Egress ✅"]
    end

    R1 & R2 & R3 & R4 --> SP["🔒 security-policy"]

    SP --> AWS_SG["aws_security_group_rule"]
    SP --> AWS_NACL["aws_network_acl"]
    SP --> AZ_NSG["azurerm_network_security_rule"]
    SP --> AZ_FW["azurerm_firewall_network_rule"]
    SP --> GCP_FW["google_compute_firewall"]
    SP --> OCI_SL["oci_core_security_list"]
    SP --> OCI_NSG["oci_core_nsg_security_rule"]

    style SP fill:#2d6a4f,stroke:#40916c,color:#fff
```

---

## 📁 Estrutura do Projeto

```
📦 multicloud-security/
├── 📄 main.tf                    # Composição de todos os módulos
├── 📄 providers.tf               # Declaração dos 4 providers
├── 📄 variables.tf               # Variáveis globais (CIDRs, regiões, tags)
├── 📄 outputs.tf                 # IDs de rede de cada cloud
├── 📄 backend.tf                 # Config do state remoto (S3/Blob/GCS)
├── 📄 terraform.tfvars.example   # Template de configuração
├── 📄 .gitignore                 # Protege state e credenciais
│
├── 📂 modules/
│   ├── 📂 security-policy/       # 🔒 Regras normalizadas (FONTE ÚNICA)
│   │   └── main.tf               #    Baseline + regras por ambiente
│   │
│   ├── 📂 aws/                   # ☁️ Amazon Web Services
│   │   ├── main.tf               #    VPC, Subnets, SGs, NACLs, Flow Logs
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── 📂 azure/                 # ☁️ Microsoft Azure
│   │   ├── main.tf               #    VNet, NSGs, Firewall, UDRs, Logs
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── 📂 gcp/                   # ☁️ Google Cloud Platform
│   │   ├── main.tf               #    VPC, Firewall Rules, Cloud NAT
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── 📂 oci/                   # ☁️ Oracle Cloud Infrastructure
│   │   ├── main.tf               #    VCN, Security Lists, NSGs, Gateways
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── 📂 connectivity/          # 🔗 VPN, Peering, Interconnect
│       └── main.tf               #    AWS↔Azure, AWS↔On-prem
│
├── 📂 environments/
│   ├── 📂 dev/                   # 🟢 Desenvolvimento
│   │   └── main.tf
│   ├── 📂 staging/               # 🟡 Staging
│   │   └── main.tf
│   └── 📂 prod/                  # 🔴 Produção (Firewall habilitado)
│       └── main.tf
│
└── 📂 docs/                      # 📖 Documentação adicional
    ├── ARCHITECTURE.md            #    Detalhes da arquitetura
    ├── MODULES.md                 #    Referência dos módulos
    ├── SECURITY.md                #    Políticas e compliance
    └── RUNBOOK.md                 #    Procedimentos operacionais
```

---

## 💻 Requisitos de Sistema / System Requirements

### 🇧🇷 Português (BR) — Configuração Mínima & Recomendada

A arquitetura deste projeto **Terraform Multi-Cloud IaC** é executada a partir de uma estação de controle local ou runner CI/CD para orquestrar redes e políticas de segurança em **AWS, Azure, GCP e OCI**, operando em três perfis de hardware:

| Recurso | 🟢 Mínimo (Validação Local / 1 Cloud em Dev) | 🟡 Intermediário (Deploy Multi-Cloud Dev/Staging — 4 Clouds) | 🔵 Recomendado (CI/CD Enterprise / Produção Multi-AZ) |
| :--- | :--- | :--- | :--- |
| **CPU** | **2 vCPUs** (`x86_64` / `arm64`) | **2 a 4 vCPUs** (`x86_64` / `arm64`) | **4+ vCPUs** (`x86_64` / `arm64`) |
| **Memória RAM** | **2 GB RAM** | **4 GB RAM** | **8 GB+ RAM** |
| **Armazenamento (SSD)** | **2 GB livres** (Terraform + cache de providers) | **5 GB livres** (4 providers ~1.2 GB + CLIs + arquivos `tfplan`) | **10 GB+ SSD** (cache persistente de providers, logs e pipelines paralelos) |
| **GPU (Opcional)** | Não necessária | Não necessária | Não necessária |
| **Sistema Operacional** | Linux (Ubuntu 22.04+/Debian 12+), macOS 12+ ou Windows 10/11 (WSL2) | Linux, macOS ou Windows (WSL2) | Linux (Runner Ubuntu 24.04 LTS / Container CI) |

#### 📦 Consumo por Componente da Arquitetura
- **Terraform Core CLI (`>= 1.5.0`) + 4 Providers Simultâneos (`aws`, `azurerm`, `google`, `oci`)**: ~400 MB a 1.5 GB de RAM durante `terraform plan`/`apply` paralelo e ~1 GB a 1.5 GB em disco no diretório `.terraform/providers`.
- **CLIs de Autenticação Cloud (`AWS CLI`, `Azure CLI`, `gcloud CLI`, `OCI CLI`)**: ~100 MB a 300 MB de RAM durante a autenticação e ~1.5 GB a 2.5 GB em disco combinados.
- **Recursos Provisionados em Nuvem (Remotos)**: VPC/VNet/VCN, Security Groups/NSGs/Firewall Rules, Flow Logs, State Remoto (`S3 + DynamoDB`, `Azure Blob` ou `GCS`) e, em ambiente `prod`, **Azure Firewall** (`~$1.25/hora`).

#### 🛠️ Dependências de Software
- **Motor IaC & Versionamento**: `Terraform >= 1.5.0`, `Git`
- **Providers Terraform (instalados via `terraform init`)**: `hashicorp/aws ~> 5.0`, `hashicorp/azurerm ~> 3.0`, `hashicorp/google ~> 5.0`, `oracle/oci ~> 5.0`
- **CLIs & Credenciais Cloud**: `AWS CLI >= 2.0`, `Azure CLI >= 2.0`, `Google Cloud SDK (gcloud)`, `OCI CLI` e contas/permissões IAM configuradas

### 🇺🇸 English — Minimum & Recommended Configuration

This **Multi-Cloud Terraform IaC** architecture runs from a local workstation or CI/CD runner to orchestrate network infrastructure and unified security policies across **AWS, Azure, GCP, and OCI**, supporting three hardware profiles:

| Resource | 🟢 Minimum (Local Validation / Single-Cloud Dev) | 🟡 Intermediate (Multi-Cloud Dev/Staging — 4 Clouds) | 🔵 Recommended (Enterprise CI/CD / Multi-AZ Prod) |
| :--- | :--- | :--- | :--- |
| **CPU** | **2 vCPUs** (`x86_64` / `arm64`) | **2 to 4 vCPUs** (`x86_64` / `arm64`) | **4+ vCPUs** (`x86_64` / `arm64`) |
| **RAM** | **2 GB RAM** | **4 GB RAM** | **8 GB+ RAM** |
| **Storage (SSD)** | **2 GB free** (Terraform + provider cache) | **5 GB free** (4 providers ~1.2 GB + CLIs + `tfplan` files) | **10 GB+ SSD** (persistent provider cache, logs & parallel pipelines) |
| **GPU (Optional)** | Not required | Not required | Not required |
| **Operating System** | Linux (Ubuntu 22.04+/Debian 12+), macOS 12+, or Windows 10/11 (WSL2) | Linux, macOS, or Windows (WSL2) | Linux (Ubuntu 24.04 LTS Runner / CI Container) |

#### 📦 Resource Usage by Architecture Component
- **Terraform Core CLI (`>= 1.5.0`) + 4 Concurrent Providers (`aws`, `azurerm`, `google`, `oci`)**: ~400 MB to 1.5 GB RAM during parallel `terraform plan`/`apply` and ~1 GB to 1.5 GB disk space in `.terraform/providers`.
- **Cloud Authentication CLIs (`AWS CLI`, `Azure CLI`, `gcloud CLI`, `OCI CLI`)**: ~100 MB to 300 MB RAM during auth and ~1.5 GB to 2.5 GB combined disk usage.
- **Cloud-Provisioned Infrastructure (Remote)**: VPC/VNet/VCN, Security Groups/NSGs/Firewall Rules, Flow Logs, Remote State (`S3 + DynamoDB`, `Azure Blob`, or `GCS`), plus **Azure Firewall** in `prod` (`~$1.25/hour`).

#### 🛠️ Software Dependencies
- **IaC Engine & VCS**: `Terraform >= 1.5.0`, `Git`
- **Terraform Providers (fetched via `terraform init`)**: `hashicorp/aws ~> 5.0`, `hashicorp/azurerm ~> 3.0`, `hashicorp/google ~> 5.0`, `oracle/oci ~> 5.0`
- **Cloud CLIs & Credentials**: `AWS CLI >= 2.0`, `Azure CLI >= 2.0`, `Google Cloud SDK (gcloud)`, `OCI CLI`, and valid IAM credentials for enabled clouds

---

## 🚀 Início Rápido

### Pré-requisitos

| Ferramenta | Versão | Instalação |
|---|---|---|
| Terraform | >= 1.5.0 | [Download](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | >= 2.0 | `aws configure` |
| Azure CLI | >= 2.0 | `az login` |
| gcloud CLI | latest | `gcloud auth application-default login` |
| OCI CLI | latest | `~/.oci/config` |

### 1. Clonar e Configurar

```bash
git clone https://github.com/SEU_USUARIO/multicloud-network-security.git
cd multicloud-network-security

# Copiar e preencher variáveis
cp terraform.tfvars.example terraform.tfvars
# ⚠️ Editar com seus valores reais (credenciais, CIDRs, etc.)
```

### 2. Inicializar e Validar

```bash
# Inicializar providers e módulos
terraform init

# Validar sintaxe e referências
terraform validate

# Verificar formatação
terraform fmt -check -recursive
```

### 3. Planejar e Aplicar

```bash
# Ver o plano completo (dry-run)
terraform plan -out=tfplan

# Aplicar as mudanças
terraform apply tfplan
```

### 4. Deploy por Ambiente

```bash
# Exemplo: deploy em desenvolvimento
cd environments/dev
terraform init
terraform plan
terraform apply
```

### 5. O Teste Definitivo ⚡

```bash
# Destruir TUDO
terraform destroy -auto-approve

# Reconstruir do ZERO — todas as regras reaplicadas automaticamente
terraform apply -auto-approve

# Tempo esperado: < 10 minutos 🎯
```

---

## 📦 Módulos

### `security-policy` — Fonte Única de Verdade

O coração do projeto. Define regras em formato agnóstico que cada provider consome:

```hcl
# Exemplo de regra normalizada
{
  name        = "allow-https"
  port        = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Permitir HTTPS"
}
```

**Comportamento por ambiente:**
- **prod**: Apenas HTTPS e SSH restrito
- **dev/staging**: Adiciona HTTP interno (porta 80)

📖 [Documentação detalhada dos módulos →](docs/MODULES.md)

---

## 🔒 Regras de Segurança

### Baseline (todas as clouds)

| Regra | Porta | Protocolo | Direção | Ambiente | CIDR |
|---|---|---|---|---|---|
| ✅ HTTPS | 443 | TCP | Ingress | Todos | `0.0.0.0/0` |
| 🔒 SSH restrito | 22 | TCP | Ingress | Todos | `10.0.0.0/8` |
| 🌐 HTTP interno | 80 | TCP | Ingress | dev/staging | `10.0.0.0/8` |
| ❌ Deny All | * | * | Ingress | Todos | `0.0.0.0/0` |
| ✅ Allow All | * | * | Egress | Todos | `0.0.0.0/0` |

### Adicionar Regras Customizadas

```hcl
# No terraform.tfvars
additional_ingress_rules = [
  {
    name        = "allow-rdp"
    port        = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "RDP para redes internas"
  },
  {
    name        = "allow-k8s-api"
    port        = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Kubernetes API Server"
  }
]
```

📖 [Política de segurança completa →](docs/SECURITY.md)

---

## 🌐 Conectividade

```mermaid
graph LR
    ONPREM["🏢 On-Premises<br/>PABs / Lojas"] ---|"🔐 VPN IPSec<br/>SD-WAN"| AWS
    AWS["☁️ AWS<br/>10.10.0.0/16"] ---|"🔐 VPN<br/>Site-to-Site"| AZURE["☁️ Azure<br/>10.20.0.0/16"]
    AZURE ---|"⚡ Interconnect<br/>Latência sub-2ms"| OCI["☁️ OCI<br/>10.40.0.0/16"]
    AWS ---|"🔐 VPN"| GCP["☁️ GCP<br/>10.30.0.0/16"]

    style AWS fill:#ff9900,stroke:#cc7a00,color:#fff
    style AZURE fill:#0078d4,stroke:#005a9e,color:#fff
    style GCP fill:#4285f4,stroke:#2a6acf,color:#fff
    style OCI fill:#f80000,stroke:#c60000,color:#fff
    style ONPREM fill:#555,stroke:#777,color:#fff
```

| Conexão | Tipo | Criptografia | Latência |
|---|---|---|---|
| AWS ↔ Azure | VPN Site-to-Site (IPSec) | AES-256 | ~15ms |
| Azure ↔ OCI | Interconnect Direto | Nativo | **< 2ms** |
| AWS ↔ On-prem | VPN + SD-WAN | AES-256 | Variável |
| GCP ↔ Hub | Cloud VPN | AES-256 | ~10ms |

Habilite via variáveis:

```hcl
enable_aws_azure_vpn = true
enable_onprem_vpn    = true
```

---

## 📊 Monitoramento e Logging

Cada cloud envia logs de tráfego para seu serviço nativo:

| Cloud | Recurso Monitorado | Destino | Retenção |
|---|---|---|---|
| AWS | VPC Flow Logs | CloudWatch Logs | 30 dias |
| Azure | NSG Diagnostics | Log Analytics Workspace | 30 dias |
| GCP | Subnet Flow Logs | Cloud Logging | Padrão GCP |
| OCI | VCN Flow Logs | OCI Logging | Padrão OCI |

---

## 🌍 Ambientes

```mermaid
graph LR
    DEV["🟢 DEV<br/>CIDRs menores<br/>1 AZ<br/>Sem Firewall"] --> STG["🟡 STAGING<br/>CIDRs médios<br/>2 AZs<br/>Sem Firewall"]
    STG --> PROD["🔴 PROD<br/>CIDRs completos<br/>3 AZs<br/>Firewall ATIVO<br/>DMZ"]

    style DEV fill:#2d6a4f,stroke:#40916c,color:#fff
    style STG fill:#e9c46a,stroke:#d4a843,color:#333
    style PROD fill:#e63946,stroke:#c5303c,color:#fff
```

| Característica | Dev | Staging | Prod |
|---|---|---|---|
| Availability Zones | 1 | 2 | 3 |
| Azure Firewall | ❌ | ❌ | ✅ |
| HTTP (porta 80) | ✅ | ✅ | ❌ |
| Subnet DMZ | ❌ | ❌ | ✅ |
| CIDR /24 Subnets | 1 pub + 1 priv | 2 pub + 2 priv | 3 pub + 3 priv |

---

## 🏷️ Tags / Labels

Todos os recursos são tagueados automaticamente para governança:

```hcl
{
  Project     = "multicloud-security"
  Environment = "dev" | "staging" | "prod"
  ManagedBy   = "terraform"
  Owner       = "heavyscan"
}
```

---

## ⚠️ Notas Importantes

> **🔑 State Remoto:** Configure o `backend.tf` antes de usar em produção. O state contém dados sensíveis.

> **🔐 Credenciais:** **NUNCA** comite `terraform.tfvars` no Git. Ele está no `.gitignore`.

> **💰 Azure Firewall:** Habilitado automaticamente em `prod`. Custo: ~$1.25/hora (~$900/mês).

> **🔒 SSH:** Por padrão restrito a `10.0.0.0/8`. Ajuste `allowed_ssh_cidrs` conforme sua rede.

---

## 🤝 Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/nova-regra`
3. Faça suas alterações
4. Valide: `terraform fmt && terraform validate`
5. Abra um Pull Request

---

## 📖 Referências

| Recurso | Link |
|---|---|
| Terraform Multi-Cloud | [HashiCorp Tutorials](https://developer.hashicorp.com/terraform/tutorials) |
| Azure Hub-Spoke | [Microsoft Reference Architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke) |
| AWS VPC Security | [AWS Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/security.html) |
| GCP Firewall | [Cloud Firewall Docs](https://cloud.google.com/vpc/docs/firewalls) |
| OCI Networking | [Oracle Docs](https://docs.oracle.com/iaas/Content/Network/Concepts/overview.htm) |

---

## 📜 Licença

MIT License — veja [LICENSE](LICENSE) para detalhes.

---

<div align="center">

**Criado por @heavyscan 🛡️**

*Infraestrutura Multi-Cloud as Code.*

</div>
