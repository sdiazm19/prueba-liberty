# Devuelve el nombre del bucket para validación/uso en otros módulos o scripts
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

# Devuelve el ARN del bucket (útil para IAM/policies)
output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}
