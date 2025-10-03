variable "proyecto_nombre" {
  description = "Nombre del proyecto (prefijo para recursos). Ej: datos_ventas"
  type        = string
}

variable "aws_region" {
  description = "Región AWS donde desplegar la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "glue_worker_type" {
  description = "Tipo de worker para Glue (e.g., G.1X, G.2X)"
  type        = string
  default     = "G.1X"
}

variable "glue_workers_count" {
  description = "Número de workers para el job de Glue"
  type        = number
  default     = 2
}

variable "input_key_prefix" {
  description = "Prefijo dentro del bucket input donde se subirán los CSV"
  type        = string
  default     = "input"
}

variable "output_key_prefix" {
  description = "Prefijo dentro del bucket output donde se escribirá Parquet"
  type        = string
  default     = "output"
}
