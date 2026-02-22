# ============================================================================
# Módulo AWS — Outputs
# ============================================================================

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR da VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "security_group_id" {
  description = "ID do Security Group principal"
  value       = aws_security_group.main.id
}

output "nat_gateway_ip" {
  description = "IP público do NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "flow_log_group" {
  description = "Nome do CloudWatch Log Group dos Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs.name
}
