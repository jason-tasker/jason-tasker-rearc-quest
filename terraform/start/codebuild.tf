# Buildspec file for creating resources with Terraform
data "template_file" "buildspec_create" {
  template = file("../buildspec/buildspec-create.yml")
}

# Buildspec file for destroying resources with Terraform
data "template_file" "buildspec_destroy" {
  template = file("../buildspec/buildspec-destroy.yml")
}

# Codebuild project for creating resources with Terraform
resource "aws_codebuild_project" "project_codebuild_create" {
  name          = "${var.project_name}-codebuild_create"
  service_role  = aws_iam_role.codebuild_role.arn
  description   = "${var.project_name}-codebuild_create"
  build_timeout = "30"
  artifacts {
    encryption_disabled    = false
    name                   = "project-start.zip"
    override_artifact_name = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"

  }
  source {
    buildspec           = data.template_file.buildspec_create.rendered
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"

  }
}

# Codebuild project for destroying resources with Terraform
resource "aws_codebuild_project" "project_codebuild_destroy" {
  name          = "${var.project_name}-codebuild_destroy"
  service_role  = aws_iam_role.codebuild_role.arn
  description   = "${var.project_name}-codebuild_destroy"
  build_timeout = "30"
  artifacts {
    encryption_disabled    = false
    name                   = "project-start.zip"
    override_artifact_name = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"

  }
  source {
    buildspec           = data.template_file.buildspec_destroy.rendered
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"

  }
}


# Codebuild role
resource "aws_iam_role" "codebuild_role" {
  name               = "${var.project_name}-codebuild"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Codebuild policy
resource "aws_iam_role_policy" "codebuild_role_policy" {
  name   = "${var.project_name}-codebuild_policy"
  role   = aws_iam_role.codebuild_role.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:us-east-1:*:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "*"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "kms:*",
        "ec2:*",
        "ecr:*",
        "ecs:*",
        "iam:*",
        "autoscaling:*",
        "elasticloadbalancing:*",
        "application-autoscaling:*"

      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}
