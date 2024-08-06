# Jason Tasker - Rearc Quest

## Notes
This is a POC and not intended to be run full time.  There are some IAM policies that may provide too much access. Please destroy the resources shortly after deployment.

## Screenshot
![Screenshot](images/tasker-demo-screenshot.png)

## Requirements

* Terraform >= 1.2.0
* Terraform AWS Provider >= 4.16

* S3 bucket - named "tasker-demo-artifact" - Hardcoded for this POC and should be adjusted for real world deployments. Bucket is used for code artifacts and Terraform State files.
* Allowed CIDR Block - 99.32.72.96/32 - Hardcoded to my IP for this POC and should be adjusted for real world deployments. Adjust terraform/container/terraform.tfvars

## Resources used

* AWS Account
* VPC
* EC2
* S3
* ECS
* ECR
* CodeBuild
* CodePipeline
* IAM
* Elastic Load Balancer

## Deployment

1. git clone repository
2. cd into repository directory
3. cd terraform/start
4. terraform init
5. terraform validate
6. terraform apply

## Deployment Explanation
1. terraform/start - Deploy codepipline that uses codebuild to deploy the infrastructure needed.  The build process installs terraform, deploys terraform/infrastructure to create ECR and VPC, then deploys the Dockerfile to ECR. Then the build will deploy terraform/container to deploy ECS.
2. terraform/infrastructure - Deploys ECR and VPC. Uses Terraform VPC module by terraform-aws-modules
3. terraform/container - Deploys the ECS container, IAM Certificate, and Application Load Balancer. Uses a custom Terraform module as an example but could be adjusted to use the Terraform ECS module

## Recreate self-signed certificate if needed
1. cd terraform/container/modules/ecs/ssl
2. openssl genrsa 2048 > privatekey.key
3. openssl req -new -x509 -nodes -sha256 -days 365 -key privatekey.key -outform PEM -out certificate.crt

## Improvements
1. Switch Codepipeline to use Github as source instead of S3
2. Use ACM for ALB certificate (requires valid DNS zone and Route53)
3. Use Terraform ECS module by terraform-aws-modules
4. Add static code analysis like checkov, tfsec, terrascan, tflint, etc to the build process