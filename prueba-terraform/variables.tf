variable "aws_region" {
  description = "AWS region para crear el bucket."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre de la app del escenario (tag ProjectName)."
  type        = string
}

variable "owner" {
  description = "Nombre de la BU (tag Owner)."
  type        = string
}

variable "bucket_name" {
  description = "Nombre único global del bucket S3 (S3 exige unicidad global)."
  type        = string
}

# BONUS: puedes restringir por VPC Endpoint (recomendado cuando hay acceso privado desde VPC)
variable "allowed_vpce_id" {
  description = "ID del VPC Endpoint (Gateway) de S3 permitido. Si es null, no se aplica restricción por VPCE."
  type        = string
  default     = null
}

# BONUS alternativo: o restringir por rangos IP (útil si el acceso viene de oficinas/VPNs conocidas)
variable "allowed_ip_cidrs" {
  description = "Lista de CIDRs permitidos. Si está vacío, no se aplica restricción por IP."
  type        = list(string)
  default     = []
}
