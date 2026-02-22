# ============================================================================
# Ambiente DEV — Configuração
# ============================================================================
# Wrapper que chama a composição principal com parâmetros de dev.
# CIDRs menores, recursos menos custosos, firewall desabilitado.
# ============================================================================

module "infra" {
  source = "../../"

  project_name = "multicloud-security"
  environment  = "dev"
  owner        = "platform-team"

  # AWS — CIDRs menores para dev
  aws_region          = "us-east-1"
  aws_vpc_cidr        = "10.10.0.0/16"
  aws_public_subnets  = ["10.10.1.0/24"]
  aws_private_subnets = ["10.10.10.0/24"]

  # Azure
  azure_subscription_id = ""  # Preencher
  azure_location        = "brazilsouth"
  azure_vnet_cidr       = "10.20.0.0/16"
  azure_subnets = {
    "public"              = "10.20.1.0/24"
    "private"             = "10.20.10.0/24"
    "AzureFirewallSubnet" = "10.20.250.0/26"
  }

  # GCP
  gcp_project_id  = ""  # Preencher
  gcp_region      = "southamerica-east1"
  gcp_subnet_cidr = "10.30.1.0/24"

  # OCI
  oci_region              = "sa-saopaulo-1"
  oci_compartment_id      = ""  # Preencher
  oci_vcn_cidr            = "10.40.0.0/16"
  oci_public_subnet_cidr  = "10.40.1.0/24"
  oci_private_subnet_cidr = "10.40.10.0/24"
}
