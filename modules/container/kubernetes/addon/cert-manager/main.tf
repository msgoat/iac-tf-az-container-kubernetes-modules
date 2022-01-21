terraform {
  required_providers {
    azurerm = {
      version = "~> 2.46"
    }
    helm = {
      version = "~> 2.1.2"
    }
    kubernetes = {
      version = "~> 2.1.0"
    }
  }
}

locals {
  module_common_tags = var.common_tags
  solution_fqn = var.solution_fqn
}
