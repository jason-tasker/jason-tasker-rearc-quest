# Archive the project
data "archive_file" "project_start_zip" {
  type        = "zip"
  output_path = "../../project-start.zip"
  excludes = [
    "*.zip"
  ]
  source_dir = "../../"
}


# Upload Project Zip file to S3 Bucket
resource "aws_s3_bucket_object" "project_start_zip" {
  key    = "project-start.zip"
  bucket = var.artifact_bucket
  source = "../../project-start.zip"

  force_destroy = true

  provisioner "local-exec" {
    command = "rm ../../project-start.zip"
  }
}
