# Tarea 2 – Terraform (AWS) | Bucket de objetos seguro

En esta tarea aprovisioné, mediante **Terraform**, un recurso de almacenamiento de objetos en **AWS (S3)** siguiendo requisitos de gobernanza para datos **PII**: cifrado en reposo con llaves gestionadas por el proveedor, versionamiento habilitado y acceso privado por defecto (no público).

## Qué implementé

- Un **bucket S3** (prueba-liberty) para la aplicación del escenario (manejo de PII).
- **Cifrado en reposo por defecto** a nivel de bucket usando cifrado gestionado por el proveedor (SSE-S3 / AES256).
- **Versionamiento** habilitado a nivel de bucket para proteger contra borrados/modificaciones accidentales y facilitar recuperación.
- **Acceso privado por defecto**, habilitando el bloqueo de acceso público (Block Public Access) para evitar exposición involuntaria.
- **Etiquetado (tagging)** consistente para trazabilidad y gobierno: Environment=Production, ProjectName=prueba-liberty, DataClassification=PII, Owner=prueba-liberty.
- **(Bonus)** Política del bucket que restringe el acceso solo a un rango de IP definido, denegando solicitudes desde otras IPs.

## Decisiones de diseño

- **SSE-S3 (AES256)**: Elegí cifrado con llaves gestionadas por el proveedor (en lugar de CMK) para cumplir el requisito de la prueba y simplificar la gestión operativa, manteniendo protección adecuada para el caso de uso.
- **Block Public Access**: Las cuatro banderas se habilitaron para garantizar que el bucket no pueda exponerse públicamente, incluso si alguien intenta configurar ACLs o políticas públicas por error.
- **Versioning**: Habilitar versioning protege contra pérdidas de datos accidentales y permite auditoría/rollback, crítico para datos PII.
- **Bucket Policy (bonus)**: La política usa una condición NotIpAddress con efecto Deny para implementar un allowlist estricto; esto asegura que incluso credenciales válidas desde IPs no autorizadas sean bloqueadas.

## Cómo lo ejecuté

Inicialicé Terraform para descargar el provider y preparar el directorio de trabajo con terraform init. Apliqué formato y validé la configuración con terraform fmt y terraform validate. Generé un plan para revisar los cambios a aplicar con terraform plan y ejecuté el aprovisionamiento con terraform apply.

## Cómo verifiqué que cumplía los requisitos

Después de aplicar, validé los controles del bucket usando AWS CLI:

### Acceso privado por defecto (bloqueo de acceso público)

Comando: aws s3api get-public-access-block --bucket prueba-liberty

Resultado: Las cuatro banderas (BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy, RestrictPublicBuckets) en true.

### Versionamiento habilitado

Comando: aws s3api get-bucket-versioning --bucket prueba-liberty

Resultado: Status Enabled.

### Cifrado por defecto habilitado

Comando: aws s3api get-bucket-encryption --bucket prueba-liberty

Resultado: Regla con SSEAlgorithm AES256.

### Tags requeridos

Comando: aws s3api get-bucket-tagging --bucket prueba-liberty

Resultado: Confirmé presencia de Environment=Production, ProjectName=prueba-liberty, DataClassification=PII, Owner=prueba-liberty.

### Bonus: política por IP

Comando: aws s3api get-bucket-policy --bucket prueba-liberty --query Policy --output text | jq .

Resultado: Política con statement Deny y condición NotIpAddress sobre aws:SourceIp, restringiendo acceso al rango configurado.

## Archivos entregados

- providers.tf – Configuración del provider AWS y tags por defecto.
- variables.tf – Definición de variables.
- main.tf – Recursos (bucket, cifrado, versionamiento, public access block, ownership controls y política).
- outputs.tf – Outputs (nombre y ARN del bucket).
- README.md – Este documento.
- .terraform.lock.hcl – Lockfile de providers (versionado para reproducibilidad).
