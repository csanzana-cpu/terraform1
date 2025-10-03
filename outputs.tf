output "input_bucket" {
  description = "Nombre del bucket de entrada (raw)"
  value       = aws_s3_bucket.input.bucket
}

output "output_bucket" {
  description = "Nombre del bucket de salida (processed)"
  value       = aws_s3_bucket.output.bucket
}

output "scripts_bucket" {
  description = "Nombre del bucket donde está almacenado el script"
  value       = aws_s3_bucket.scripts.bucket
}

output "glue_job_name" {
  description = "Nombre del Glue Job"
  value       = aws_glue_job.etl_job.name
}

output "glue_role_arn" {
  description = "ARN del role IAM usado por Glue"
  value       = aws_iam_role.glue_service_role.arn
}
