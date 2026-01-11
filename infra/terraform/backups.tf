# =============================================================================
# BACKUPS INFRASTRUCTURE
# =============================================================================
# Creates an S3 bucket for database backups and an IAM user with access to it.
# =============================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 1. S3 Bucket
resource "aws_s3_bucket" "backups" {
  bucket = "${var.project_name}-db-backups-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-backups"
    Environment = var.environment
  }
}

# Enable versioning (safety against accidental overwrites)
resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rule - keep backups for 30 days
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    filter {} # Required - empty filter means apply to all objects

    expiration {
      days = 30
    }
  }
}

# Block public access (Security Best Practice!)
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. IAM User for the Backup Script
resource "aws_iam_user" "backup_user" {
  name = "${var.project_name}-backup-bot"

  tags = {
    Environment = var.environment
  }
}

# Generate Access Keys for the user
resource "aws_iam_access_key" "backup_user" {
  user = aws_iam_user.backup_user.name
}

# 3. Policy (Give user access ONLY to this bucket)
resource "aws_iam_user_policy" "backup_policy" {
  name = "${var.project_name}-s3-write-policy"
  user = aws_iam_user.backup_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.backups.arn,
          "${aws_s3_bucket.backups.arn}/*"
        ]
      }
    ]
  })
}
