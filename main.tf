# ============================================================================
# Main — Composição de todos os módulos
# ============================================================================
# Este é o ponto de entrada que orquestra todos os módulos.
# Cada módulo de provider recebe as regras normalizadas do security-policy.
# ============================================================================

# -----------------------------------------------------------------------------
# 1. Módulo Security Policy (fonte única de verdade para regras)
# -----------------------------------------------------------------------------
module "security_policy" {
  source = "./modules/security-policy"

  environment            = var.environment
  additional_ingress_rules = var.additional_ingress_rules
}

# -----------------------------------------------------------------------------
# 2. AWS — VPC, Security Groups, NACLs, Flow Logs
# -----------------------------------------------------------------------------
module "aws_network" {
  source = "./modules/aws"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.aws_vpc_cidr
  public_subnet_cidrs  = var.aws_public_subnets
  private_subnet_cidrs = var.aws_private_subnets
  ingress_rules        = module.security_policy.ingress_rules
  egress_rules         = module.security_policy.egress_rules
  tags                 = local.common_tags
}

# -----------------------------------------------------------------------------
# 3. Azure — VNet, NSGs, Firewall, Route Tables
# -----------------------------------------------------------------------------
module "azure_network" {
  source = "./modules/azure"

  project_name    = var.project_name
  environment     = var.environment
  location        = var.azure_location
  vnet_cidr       = var.azure_vnet_cidr
  subnets         = var.azure_subnets
  ingress_rules   = module.security_policy.ingress_rules
  enable_firewall = var.environment == "prod" ? true : false
  tags            = local.common_tags
}

# -----------------------------------------------------------------------------
# 4. GCP — VPC, Firewall Rules, Cloud NAT
# -----------------------------------------------------------------------------
module "gcp_network" {
  source = "./modules/gcp"

  project_name  = var.project_name
  environment   = var.environment
  region        = var.gcp_region
  subnet_cidr   = var.gcp_subnet_cidr
  ingress_rules = module.security_policy.ingress_rules
  tags          = local.common_tags
}

# -----------------------------------------------------------------------------
# 5. OCI — VCN, Security Lists, NSGs
# -----------------------------------------------------------------------------
module "oci_network" {
  source = "./modules/oci"

  project_name        = var.project_name
  environment         = var.environment
  compartment_id      = var.oci_compartment_id
  vcn_cidr            = var.oci_vcn_cidr
  public_subnet_cidr  = var.oci_public_subnet_cidr
  private_subnet_cidr = var.oci_private_subnet_cidr
  ingress_rules       = module.security_policy.ingress_rules
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# 6. Conectividade (desabilitada por padrão — habilite via variáveis)
# -----------------------------------------------------------------------------
module "connectivity" {
  source = "./modules/connectivity"

  project_name          = var.project_name
  environment           = var.environment
  enable_aws_azure_vpn  = false
  enable_onprem_vpn     = false
  aws_vpc_id            = module.aws_network.vpc_id
  aws_vpc_cidr          = var.aws_vpc_cidr
  tags                  = local.common_tags
}
