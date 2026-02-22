# ============================================================================
# Módulo OCI — Rede Segura (VCN, Gateways, Subnets, Security Lists, NSGs)
# ============================================================================

# -----------------------------------------------------------------------------
# VCN (Virtual Cloud Network)
# -----------------------------------------------------------------------------
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-vcn-${var.environment}"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = replace("${var.project_name}${var.environment}", "-", "")

  freeform_tags = var.tags
}

# -----------------------------------------------------------------------------
# Gateways
# -----------------------------------------------------------------------------
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-igw-${var.environment}"
  enabled        = true

  freeform_tags = var.tags
}

resource "oci_core_nat_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-nat-${var.environment}"

  freeform_tags = var.tags
}

resource "oci_core_service_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-sgw-${var.environment}"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }

  freeform_tags = var.tags
}

data "oci_core_services" "all_services" {}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-rt-public-${var.environment}"

  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Rota para internet via IGW"
  }

  freeform_tags = var.tags
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-rt-private-${var.environment}"

  route_rules {
    network_entity_id = oci_core_nat_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Rota para internet via NAT Gateway"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.main.id
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    description       = "Rota para Oracle Services via Service Gateway"
  }

  freeform_tags = var.tags
}

# -----------------------------------------------------------------------------
# Security Lists (camada de subnet)
# -----------------------------------------------------------------------------
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-sl-public-${var.environment}"

  # Regras de Ingress dinâmicas (do security-policy)
  dynamic "ingress_security_rules" {
    for_each = var.ingress_rules
    content {
      protocol    = ingress_security_rules.value.protocol == "tcp" ? "6" : (ingress_security_rules.value.protocol == "udp" ? "17" : "all")
      source      = ingress_security_rules.value.cidr_blocks[0]
      source_type = "CIDR_BLOCK"
      description = ingress_security_rules.value.description
      stateless   = false

      dynamic "tcp_options" {
        for_each = ingress_security_rules.value.protocol == "tcp" ? [1] : []
        content {
          min = ingress_security_rules.value.port
          max = ingress_security_rules.value.port
        }
      }

      dynamic "udp_options" {
        for_each = ingress_security_rules.value.protocol == "udp" ? [1] : []
        content {
          min = ingress_security_rules.value.port
          max = ingress_security_rules.value.port
        }
      }
    }
  }

  # Egress — Allow All
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Permitir todo tráfego de saída"
    stateless   = false
  }

  freeform_tags = var.tags
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-sl-private-${var.environment}"

  # SSH restrito (interno)
  ingress_security_rules {
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    description = "SSH interno"
    stateless   = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTPS interno
  ingress_security_rules {
    protocol    = "6"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    description = "HTTPS interno"
    stateless   = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Egress — Allow All
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Permitir todo tráfego de saída"
    stateless   = false
  }

  freeform_tags = var.tags
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "${var.project_name}-snet-public-${var.environment}"
  cidr_block                 = var.public_subnet_cidr
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false
  dns_label                  = "pub"

  freeform_tags = var.tags
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "${var.project_name}-snet-private-${var.environment}"
  cidr_block                 = var.private_subnet_cidr
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  prohibit_public_ip_on_vnic = true
  dns_label                  = "priv"

  freeform_tags = var.tags
}

# -----------------------------------------------------------------------------
# Network Security Group (camada de VNIC — micro-segmentação fina)
# -----------------------------------------------------------------------------
resource "oci_core_network_security_group" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-nsg-${var.environment}"

  freeform_tags = var.tags
}

# NSG Rules dinâmicas (do security-policy)
resource "oci_core_network_security_group_security_rule" "ingress" {
  count                     = length(var.ingress_rules)
  network_security_group_id = oci_core_network_security_group.main.id
  direction                 = "INGRESS"
  protocol                  = var.ingress_rules[count.index].protocol == "tcp" ? "6" : (var.ingress_rules[count.index].protocol == "udp" ? "17" : "all")
  source                    = var.ingress_rules[count.index].cidr_blocks[0]
  source_type               = "CIDR_BLOCK"
  description               = var.ingress_rules[count.index].description
  stateless                 = false

  dynamic "tcp_options" {
    for_each = var.ingress_rules[count.index].protocol == "tcp" ? [1] : []
    content {
      destination_port_range {
        min = var.ingress_rules[count.index].port
        max = var.ingress_rules[count.index].port
      }
    }
  }

  dynamic "udp_options" {
    for_each = var.ingress_rules[count.index].protocol == "udp" ? [1] : []
    content {
      destination_port_range {
        min = var.ingress_rules[count.index].port
        max = var.ingress_rules[count.index].port
      }
    }
  }
}

# NSG Egress — Allow All
resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.main.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Permitir todo tráfego de saída"
  stateless                 = false
}
