terraform {
  # Versión mínima recomendada de Terraform
  required_version = ">= 1.5.0"

  # Fijamos el provider de AWS para que el código sea reproducible
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  # Región donde se crearán los recursos
  region = var.aws_region

  # Tags por defecto para TODO lo que cree este provider
  # (así garantizamos los tags requeridos por la prueba)
  default_tags {
    tags = {
      Environment        = "Production"     # Requerido
      ProjectName        = var.project_name # Requerido
      DataClassification = "PII"            # Requerido
      Owner              = var.owner        # Requerido
      ManagedBy          = "Terraform"      # Extra útil para auditoría
    }
  }
}
