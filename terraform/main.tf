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

resource "azurerm_resource_group" "rg" {
  name     = "rg-windows-vm"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-windows"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-windows"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-windows"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "winvm-github"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  admin_password      = "P@ssword1234!"  # Replace with a secure secret

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    name              = "osdisk-winvm"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
