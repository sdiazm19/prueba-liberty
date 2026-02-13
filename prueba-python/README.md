# Tarea 3 – Script de Automatización para Auditoría

Script en Python que audita buckets S3 en AWS para verificar cumplimiento de controles de gobernanza: versionamiento y encriptación por defecto.

## Requisitos

- Python 3.6 o superior
- boto3 (AWS SDK para Python)
- Credenciales de AWS configuradas

## Instalación

Instalar dependencias con pip3 install boto3 o usando entorno virtual (recomendado) con python3 -m venv venv, luego source venv/bin/activate y pip install boto3.

## Configuración de Credenciales

El script utiliza las credenciales de AWS configuradas en el entorno. Existen varias opciones seguras:

### Opción 1: AWS CLI configurado (recomendado)

Si AWS CLI ya está configurado, el script usará esas credenciales automáticamente. Las credenciales se almacenan de forma segura en el archivo de configuración de AWS. Ejecutar aws configure e ingresar las credenciales cuando se solicite. Esto creará los archivos en ~/.aws/credentials y ~/.aws/config.

### Opción 2: Variables de entorno (sesión temporal)

Para una sesión temporal sin guardar las credenciales en archivos, exportar las variables de entorno en la terminal:

export AWS_ACCESS_KEY_ID="access-key"
export AWS_SECRET_ACCESS_KEY="secret-key"
export AWS_DEFAULT_REGION="us-east-1"

Estas credenciales solo estarán disponibles en la sesión actual del terminal y se eliminarán al cerrar la terminal.

### Opción 3: Archivo .env (no versionado)

Crear un archivo .env en el directorio del script con el siguiente contenido:

AWS_ACCESS_KEY_ID=access-key
AWS_SECRET_ACCESS_KEY=secret-key
AWS_DEFAULT_REGION=us-east-1

Luego cargar las variables antes de ejecutar el script con source .env o python3 prueba-python.py. Importante: Agregar .env al archivo .gitignore para no versionar credenciales.

### Opción 4: Perfil específico de AWS

Si se usan múltiples perfiles configurados en ~/.aws/credentials, especificar el perfil a usar con export AWS_PROFILE="nombre-del-perfil".

### Opción 5: Roles de IAM (producción recomendada)

Si el script se ejecuta desde una instancia EC2, Lambda o contenedor ECS con un rol de IAM asignado, usará automáticamente las credenciales del rol sin necesidad de configuración adicional. Esta es la opción más segura para entornos productivos.

## Configuración del Script

Antes de ejecutar, modificar la región a auditar editando la variable REGION en el script (por defecto us-east-1).

## Ejecución

Ejecutar el script con python3 prueba-python.py.

## Permisos Requeridos

El usuario o rol de IAM debe tener los siguientes permisos: s3:ListAllMyBuckets, s3:GetBucketLocation, s3:GetBucketVersioning, s3:GetEncryptionConfiguration.

## Salida del Script

El script genera un informe categorizado con:

- Total de buckets analizados en la región especificada
- Recursos que cumplen con ambos requisitos (versionamiento y encriptación)
- Recursos sin versionamiento habilitado
- Recursos sin encriptación por defecto habilitada

## Ejemplo de Salida

INFORME DE AUDITORÍA DE BUCKETS S3 - REGIÓN: us-east-1

TOTAL DE BUCKETS ANALIZADOS: 3

RECURSOS QUE CUMPLEN (Versionamiento + Encriptación): prueba-liberty, production-data

RECURSOS SIN VERSIONAMIENTO: dev-bucket

RECURSOS SIN ENCRIPTACIÓN POR DEFECTO: dev-bucket

## Notas

- El script solo audita buckets en la región especificada en la variable REGION.
- Para us-east-1, AWS devuelve None como LocationConstraint, el script maneja esto correctamente.
- Los buckets que no cumplen con uno o ambos requisitos aparecerán en las secciones correspondientes del informe.
- Nunca versionar credenciales en repositorios. Usar .gitignore para excluir archivos .env o credentials.
