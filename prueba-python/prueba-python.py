import boto3
from botocore.exceptions import ClientError

# Configuración
REGION = 'us-east-1'

def check_bucket_versioning(s3_client, bucket_name):
    """Verifica si el versionamiento está habilitado en un bucket."""
    try:
        response = s3_client.get_bucket_versioning(Bucket=bucket_name)
        status = response.get('Status', 'Disabled')
        return status == 'Enabled'
    except ClientError as e:
        print(f"Error verificando versionamiento en {bucket_name}: {e}")
        return False

def check_bucket_encryption(s3_client, bucket_name):
    """Verifica si la encriptación por defecto está habilitada en un bucket."""
    try:
        s3_client.get_bucket_encryption(Bucket=bucket_name)
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'ServerSideEncryptionConfigurationNotFoundError':
            return False
        print(f"Error verificando encriptación en {bucket_name}: {e}")
        return False

def audit_s3_buckets(region):
    """Audita todos los buckets S3 en una región específica."""
    s3_client = boto3.client('s3', region_name=region)
    
    # Listar todos los buckets
    try:
        response = s3_client.list_buckets()
        buckets = response.get('Buckets', [])
    except ClientError as e:
        print(f"Error listando buckets: {e}")
        return
    
    # Filtrar buckets por región
    regional_buckets = []
    for bucket in buckets:
        bucket_name = bucket['Name']
        try:
            bucket_region = s3_client.get_bucket_location(Bucket=bucket_name)['LocationConstraint']
            # us-east-1 devuelve None como LocationConstraint
            if bucket_region is None:
                bucket_region = 'us-east-1'
            if bucket_region == region:
                regional_buckets.append(bucket_name)
        except ClientError as e:
            print(f"Error obteniendo región de {bucket_name}: {e}")
    
    # Inicializar listas para el informe
    compliant = []
    no_versioning = []
    no_encryption = []
    
    # Auditar cada bucket
    for bucket_name in regional_buckets:
        has_versioning = check_bucket_versioning(s3_client, bucket_name)
        has_encryption = check_bucket_encryption(s3_client, bucket_name)
        
        if has_versioning and has_encryption:
            compliant.append(bucket_name)
        else:
            if not has_versioning:
                no_versioning.append(bucket_name)
            if not has_encryption:
                no_encryption.append(bucket_name)
    
    # Imprimir informe
    print("=" * 80)
    print(f"INFORME DE AUDITORÍA DE BUCKETS S3 - REGIÓN: {region}")
    print("=" * 80)
    print()
    
    print(f"TOTAL DE BUCKETS ANALIZADOS: {len(regional_buckets)}")
    print()
    
    print("✓ RECURSOS QUE CUMPLEN (Versionamiento + Encriptación):")
    print("-" * 80)
    if compliant:
        for bucket in compliant:
            print(f"  • {bucket}")
    else:
        print("  (ninguno)")
    print()
    
    print("✗ RECURSOS SIN VERSIONAMIENTO:")
    print("-" * 80)
    if no_versioning:
        for bucket in no_versioning:
            print(f"  • {bucket}")
    else:
        print("  (ninguno)")
    print()
    
    print("✗ RECURSOS SIN ENCRIPTACIÓN POR DEFECTO:")
    print("-" * 80)
    if no_encryption:
        for bucket in no_encryption:
            print(f"  • {bucket}")
    else:
        print("  (ninguno)")
    print()
    
    print("=" * 80)

if __name__ == "__main__":
    print("Iniciando auditoría de gobernanza S3...\n")
    audit_s3_buckets(REGION)
