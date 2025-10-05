terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS2_v2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Reference existing Recovery Services Vault
data "azurerm_recovery_services_vault" "vault" {
  name                = var.vault_name
  resource_group_name = var.vault_resource_group
}

# Reference existing backup policy
data "azurerm_backup_policy_vm" "policy" {
  name                = var.policy_name
  resource_group_name = var.vault_resource_group
  recovery_vault_name = data.azurerm_recovery_services_vault.vault.name
}

# Enable backup protection
resource "azurerm_backup_protected_vm" "backup" {
  resource_group_name       = var.vault_resource_group
  recovery_vault_name       = data.azurerm_recovery_services_vault.vault.name
  source_vm_id              = azurerm_windows_virtual_machine.vm.id
  backup_policy_id          = data.azurerm_backup_policy_vm.policy.id
}