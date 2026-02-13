# 1 Creamos el bucket S3 (recurso base)
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

# 2 Bloqueamos acceso público a nivel bucket
# Esto ayuda a prevenir exposición accidental por ACLs o políticas públicas. [web:210][web:211]
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  # Bloquea ACLs públicas
  block_public_acls = true

  # Evita que se puedan poner políticas que hagan el bucket público
  block_public_policy = true

  # Ignora cualquier ACL pública (aunque alguien la intente configurar)
  ignore_public_acls = true

  # Restringe buckets que pudieran quedar públicos por políticas
  restrict_public_buckets = true
}

# 3 Habilitamos versionamiento (requisito de la prueba)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 4 Habilitamos cifrado en reposo (requisito de la prueba)
# SSE-S3 con AES256 = cifrado por defecto con claves gestionadas por AWS (proveedor). [web:195]
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 5) (Recomendado) Deshabilitar el uso de ACLs y forzar "Bucket owner enforced"
# Esto reduce configuraciones heredadas y evita problemas de ownership/ACLs.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 6 BONUS: Política opcional del bucket para restringir acceso
# Nota: la política está escrita como "Deny" (denegar) si NO cumple condición,
# porque en seguridad es más robusto "deny by default".
data "aws_iam_policy_document" "bucket_policy" {

  # 6.1 Restringir por VPC Endpoint (si se proporciona allowed_vpce_id)
  # Si la petición NO viene desde el VPCE permitido, se deniega. [web:200]
  dynamic "statement" {
    for_each = var.allowed_vpce_id == null ? [] : [1]
    content {
      sid     = "DenyRequestsNotFromAllowedVPCE"
      effect  = "Deny"
      actions = ["s3:*"]

      # Aplica a cualquier principal; la condición define el filtro real.
      principals {
        type        = "*"
        identifiers = ["*"]
      }

      # Protege tanto el bucket como todos sus objetos
      resources = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]

      # Condición: si el VPCE NO es el permitido → deny
      condition {
        test     = "StringNotEquals"
        variable = "aws:sourceVpce"
        values   = [var.allowed_vpce_id]
      }
    }
  }

  # 6.2 Restringir por rangos IP (si se proporciona allowed_ip_cidrs)
  # Si la petición NO viene desde una IP permitida, se deniega.
  dynamic "statement" {
    for_each = length(var.allowed_ip_cidrs) == 0 ? [] : [1]
    content {
      sid     = "DenyRequestsNotFromAllowedIPs"
      effect  = "Deny"
      actions = ["s3:*"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      resources = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
      ]

      condition {
        test     = "NotIpAddress"
        variable = "aws:SourceIp"
        values   = var.allowed_ip_cidrs
      }
    }
  }
}

# 7) Aplicamos la política solo si se configuró al menos una restricción (VPCE o IPs)
resource "aws_s3_bucket_policy" "this" {
  count  = (var.allowed_vpce_id != null || length(var.allowed_ip_cidrs) > 0) ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json

  # Asegura que el bloqueo de acceso público exista primero
  depends_on = [aws_s3_bucket_public_access_block.this]
}
