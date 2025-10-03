terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.1"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# Configurar el proveedor
provider "aws" {
    #configurar la region
  region = var.aws_region
  access_key = ""
  secret_key = ""
  token = ""
}

# Sufijo único para nombres de recursos
resource "random_id" "suffix" {
  byte_length = 4
}

# Buckets S3
resource "aws_s3_bucket" "input" {
  bucket        = "${var.proyecto_nombre}-raw-${random_id.suffix.hex}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "output" {
  bucket        = "${var.proyecto_nombre}-processed-${random_id.suffix.hex}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "scripts" {
  bucket        = "${var.proyecto_nombre}-scripts-${random_id.suffix.hex}"
  acl           = "private"
  force_destroy = true
}

# Subida del script al bucket de scripts
resource "aws_s3_bucket_object" "glue_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "glue_scripts/etl_job.py"
  source = "${path.module}/glue_scripts/etl_job.py"
  etag   = filemd5("${path.module}/glue_scripts/etl_job.py")
}

# IAM Role para Glue
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_service_role" {
  name               = "${var.proyecto_nombre}-glue-execution-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

# Política IAM para CloudWatch Logs y S3
data "aws_iam_policy_document" "glue_policy" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws-glue/*"]
  }

  statement {
    sid    = "S3AccessBuckets"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.input.arn,
      "${aws_s3_bucket.input.arn}/*",
      aws_s3_bucket.output.arn,
      "${aws_s3_bucket.output.arn}/*",
      aws_s3_bucket.scripts.arn,
      "${aws_s3_bucket.scripts.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "glue_inline_policy" {
  name   = "${var.proyecto_nombre}-glue-policy"
  role   = aws_iam_role.glue_service_role.id
  policy = data.aws_iam_policy_document.glue_policy.json
}

# creación Job de Glue
resource "aws_glue_job" "etl_job" {
  name     = "${var.proyecto_nombre}-etl-job"
  role_arn = aws_iam_role.glue_service_role.arn

  glue_version = "4.0"

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.scripts.bucket}/glue_scripts/etl_job.py"
  }

  max_retries = 0

  number_of_workers = var.glue_workers_count
  worker_type       = var.glue_worker_type

  default_arguments = {
    "--S3_INPUT_PATH"  = "s3://${aws_s3_bucket.input.bucket}/${var.input_key_prefix}"
    "--S3_OUTPUT_PATH" = "s3://${aws_s3_bucket.output.bucket}/${var.output_key_prefix}"
    "--TempDir"        = "s3://${aws_s3_bucket.scripts.bucket}/temp/"
    "--job-language"   = "python"
    "--enable-continuous-cloudwatch-log" = "true"
  }

  tags = {
    Project = var.proyecto_nombre
    Managed = "terraform"
  }
}
