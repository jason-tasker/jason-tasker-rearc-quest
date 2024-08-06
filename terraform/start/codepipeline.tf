# Codepipeline role
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Codepipeline role policy
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*",
        "kms:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create Codepipeline
# Stage 1 - Source S3
# Stage 2 - Codebuild and create resources with Terraform
# Stage 3 - Wait for Approval to Destroy resrouces
# Stage 4 - Codebuild and destroy resources created in Stage 2
resource "aws_codepipeline" "project_pipeline" {
  depends_on = [
    aws_iam_role.codepipeline_role,
    aws_s3_bucket_object.project_start_zip
  ]
  name = "${var.project_name}-codepipeline"

  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.artifact_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = var.artifact_bucket
        S3ObjectKey = "project-start.zip"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.project_codebuild_create.name
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Please approve me to destroy"
      }
    }
  }

  stage {
    name = "Destroy"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["build_output"]
      output_artifacts = ["destroy_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.project_codebuild_destroy.name
      }
    }
  }

}
