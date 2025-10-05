terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100" # Use latest stable version
    }
  }

  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}

  subscription_id = "76eca8ba-0ca7-4bf7-83d6-5c135d89de1f" # Optional if using default context
}
