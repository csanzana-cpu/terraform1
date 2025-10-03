from pyspark.sql import SparkSession
from pyspark.sql import functions as F
import sys
from awsglue.utils import getResolvedOptions

# Argumentos pasados desde Terraform en default_arguments
args = getResolvedOptions(sys.argv, ['S3_INPUT_PATH', 'S3_OUTPUT_PATH'])

s3_input = args['S3_INPUT_PATH']
s3_output = args['S3_OUTPUT_PATH']

# Inicializar Spark
spark = SparkSession.builder.appName("etl_job").getOrCreate()

# Leer CSV desde S3 (con encabezado y schema inferido)
df = spark.read.option("header", "true").option("inferSchema", "true").csv(s3_input)

# Agregar columna load_date con la fecha/hora actual
df_transformed = df.withColumn("load_date", F.current_timestamp())

# Escribir DataFrame transformado en formato Parquet
# Nota: mode="overwrite" es para pruebas. En producción puede usarse "append".
df_transformed.write.mode("overwrite").parquet(s3_output)

spark.stop()
