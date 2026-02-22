# ============================================================================
# Backend Remoto — State com Locking
# ============================================================================
# Descomente e configure o backend desejado antes de rodar terraform init.
#
# Opção 1: AWS S3 + DynamoDB (recomendado)
# terraform {
#   backend "s3" {
#     bucket         = "seu-bucket-terraform-state"
#     key            = "multicloud-security/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
#
# Opção 2: Azure Blob Storage
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "stterraformstate"
#     container_name       = "tfstate"
#     key                  = "multicloud-security.tfstate"
#   }
# }
#
# Opção 3: GCS (Google Cloud Storage)
# terraform {
#   backend "gcs" {
#     bucket = "seu-bucket-terraform-state"
#     prefix = "multicloud-security"
#   }
# }
