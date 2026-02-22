# ============================================================================
# Módulo GCP — Rede Segura (VPC, Subnets, Firewall, Cloud NAT)
# ============================================================================

# -----------------------------------------------------------------------------
# VPC (custom mode — sem subnets auto-criadas)
# -----------------------------------------------------------------------------
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# -----------------------------------------------------------------------------
# Subnet com Private Google Access e Flow Logs
# -----------------------------------------------------------------------------
resource "google_compute_subnetwork" "main" {
  name                     = "${var.project_name}-subnet-${var.environment}"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules (consumindo regras do security-policy)
# -----------------------------------------------------------------------------

# Regras de Ingress dinâmicas
resource "google_compute_firewall" "ingress" {
  count   = length(var.ingress_rules)
  name    = "${var.project_name}-${var.ingress_rules[count.index].name}-${var.environment}"
  network = google_compute_network.main.name

  direction     = "INGRESS"
  source_ranges = var.ingress_rules[count.index].cidr_blocks

  allow {
    protocol = var.ingress_rules[count.index].protocol
    ports    = [tostring(var.ingress_rules[count.index].port)]
  }

  description = var.ingress_rules[count.index].description

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Deny all — regra de baixa prioridade
resource "google_compute_firewall" "deny_all_ingress" {
  name     = "${var.project_name}-deny-all-ingress-${var.environment}"
  network  = google_compute_network.main.name
  priority = 65534

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  description = "Negar todo tráfego inbound não explicitamente permitido"
}

# Allow all egress (padrão GCP, mas explícito para governança)
resource "google_compute_firewall" "allow_all_egress" {
  name      = "${var.project_name}-allow-all-egress-${var.environment}"
  network   = google_compute_network.main.name
  priority  = 1000
  direction = "EGRESS"

  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }

  description = "Permitir todo tráfego de saída"
}

# Allow internal (comunicação entre pods/VMs na mesma rede)
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal-${var.environment}"
  network = google_compute_network.main.name

  direction     = "INGRESS"
  source_ranges = [var.subnet_cidr]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  description = "Permitir comunicação interna na rede"
}

# -----------------------------------------------------------------------------
# Cloud Router + Cloud NAT (acesso à internet para VMs sem IP público)
# -----------------------------------------------------------------------------
resource "google_compute_router" "main" {
  name    = "${var.project_name}-router-${var.environment}"
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-nat-${var.environment}"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
