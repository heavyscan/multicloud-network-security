# ============================================================================
# Ambiente PROD — Configuração
# ============================================================================
# Produção: Azure Firewall habilitado, multi-AZ, CIDRs completos.
# ============================================================================

module "infra" {
  source = "../../"

  project_name = "multicloud-security"
  environment  = "prod"
  owner        = "platform-team"

  # AWS — multi-AZ
  aws_region          = "us-east-1"
  aws_vpc_cidr        = "10.10.0.0/16"
  aws_public_subnets  = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  aws_private_subnets = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]

  # Azure — Firewall será habilitado automaticamente (environment == "prod")
  azure_subscription_id = ""  # Preencher
  azure_location        = "brazilsouth"
  azure_vnet_cidr       = "10.20.0.0/16"
  azure_subnets = {
    "public"              = "10.20.1.0/24"
    "private"             = "10.20.10.0/24"
    "dmz"                 = "10.20.20.0/24"
    "AzureFirewallSubnet" = "10.20.250.0/26"
  }

  # GCP
  gcp_project_id  = ""  # Preencher
  gcp_region      = "southamerica-east1"
  gcp_subnet_cidr = "10.30.0.0/20"

  # OCI
  oci_region              = "sa-saopaulo-1"
  oci_compartment_id      = ""  # Preencher
  oci_vcn_cidr            = "10.40.0.0/16"
  oci_public_subnet_cidr  = "10.40.1.0/24"
  oci_private_subnet_cidr = "10.40.10.0/24"
}
