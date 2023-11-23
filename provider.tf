# ---------------------------------------------------------------------------

# Specify Terraform Provider and Version
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.81.0"
    }
  }
}

provider "azurerm" {
  # Skip automatic provider registration
  skip_provider_registration = true
  features {}
}

# ---------------------------------------------------------------------------