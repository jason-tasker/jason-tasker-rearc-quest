provider "aws" {
  region = var.aws_region
}

# Lookup ECR Repo
data "aws_ecr_repository" "ecr_repo" {
  name = "${var.project_name}-ecr"
}

# Lookup Project VPC
data "aws_vpc" "project_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name} VPC"]
  }
}

# Lookup Project Public1 Subnet
data "aws_subnet" "public1_subnet" {
  vpc_id = data.aws_vpc.project_vpc.id
  filter {
    name   = "tag:Name"
    values = ["${var.project_name} Public Subnet #1"]
  }
}

# Lookup Project Public2 Subnet
data "aws_subnet" "public2_subnet" {
  vpc_id = data.aws_vpc.project_vpc.id
  filter {
    name   = "tag:Name"
    values = ["${var.project_name} Public Subnet #2"]
  }
}

# Lookup Project Private1 Subnet
data "aws_subnet" "private1_subnet" {
  vpc_id = data.aws_vpc.project_vpc.id
  filter {
    name   = "tag:Name"
    values = ["${var.project_name} Private Subnet #1"]
  }
}

# Lookup Project Private2 Subnet
data "aws_subnet" "private2_subnet" {
  vpc_id = data.aws_vpc.project_vpc.id
  filter {
    name   = "tag:Name"
    values = ["${var.project_name} Private Subnet #2"]
  }
}

# ECS service Assume role document
data "aws_iam_policy_document" "ecs_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ecs.amazonaws.com",
        "s3.amazonaws.com",
      ]
    }
  }
}

# ECS service policy
data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "codedeploy:CreateApplication",
      "codedeploy:CreateDeployment",
      "codedeploy:CreateDeploymentGroup",
      "codedeploy:GetApplication",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:ListApplications",
      "codedeploy:ListDeploymentGroups",
      "codedeploy:ListDeployments",
      "codedeploy:StopDeployment",
      "codedeploy:GetDeploymentTarget",
      "codedeploy:ListDeploymentTargets",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:BatchGetApplicationRevisions",
      "codedeploy:BatchGetDeploymentGroups",
      "codedeploy:BatchGetDeployments",
      "codedeploy:BatchGetApplications",
      "codedeploy:ListApplicationRevisions",
      "codedeploy:ListDeploymentConfigs",
      "codedpeloy:ContinueDeployment",
      "sns:ListTopics",
      "cloudwatch:DescribeAlarms",
      "lambda:ListFunctions",
    ]
  }
}

# Create IAM role for ECS Service
resource "aws_iam_role" "ecs_service_role" {
  name               = "${var.project_name}-ecs_service_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service.json
}

# Apply ECS polity to ECS Service IAM Role
resource "aws_iam_role_policy" "ecs_service_policy" {
  name   = "${var.project_name}-ecs_service_role_policy"
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ecs_service_role.id
}

# ECS Execute assume role document
data "aws_iam_policy_document" "ecs_exec" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

# ECS Execute policy document
data "aws_iam_policy_document" "ecs_exec_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecs:DescribeTaskDefinition",
      "ecs:ListServices",
      "ecs:DescribeServices",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath"
    ]
  }
}

# ECS Execute role
resource "aws_iam_role" "ecs_exec" {
  name               = "${var.project_name}-ecs_exec_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_exec.json
}

# Attach ECS Execute policy to ECS Execute role
resource "aws_iam_role_policy" "ecs_exec" {
  name   = "${var.project_name}-ecs_exec_role_policy"
  policy = data.aws_iam_policy_document.ecs_exec_policy.json
  role   = aws_iam_role.ecs_exec.id
}

# ECS Agent assume role document
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

# ECS Agent role
resource "aws_iam_role" "ecs_agent" {
  name               = "${var.project_name}-ecs_agent_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

# Attach Amazon ECS policy to ECS Agent role
resource "aws_iam_role_policy_attachment" "ecs_agent" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.ecs_agent.id
}

# Create an instance profile for ECS Agent to use on EC2 instances
resource "aws_iam_instance_profile" "ecs_agent" {
  name = "${var.project_name}-ecs_agent_role_profile"
  role = aws_iam_role.ecs_agent.name
}

# Upload self-signed cert to IAM cert store
resource "aws_iam_server_certificate" "elb_cert" {
  private_key      = file("modules/ecs/ssl/privatekey.key")
  certificate_body = file("modules/ecs/ssl/certificate.crt")
  tags = {
    Name = "${var.project_name}-cert"
  }
}

# Create Security Group for ECS ALB and allow http/https
resource "aws_security_group" "ecs_alb_sg" {
  name        = "${var.project_name}-ecs_alb_sg"
  description = "ECS ALB SG"
  vpc_id      = data.aws_vpc.project_vpc.id

  ingress {
    description = "HTTP from outside"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "HTTPS from outside"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create Security Group for ECS EC2 instances
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs_sg"
  description = "ECS SG"
  vpc_id      = data.aws_vpc.project_vpc.id

  ingress {
    description     = "HTTP from outside"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_alb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


# Create Application Load Balancer for ECS
resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_alb_sg.id]
  subnets = [
    data.aws_subnet.public1_subnet.id,
    data.aws_subnet.public2_subnet.id
  ]

  tags = {
    Environment = "production"
  }
}

# Create ALB Target group for http
resource "aws_alb_target_group" "ecs_alb_tg" {
  name        = "${var.project_name}-alb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.project_vpc.id

}

# Create http listener for ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_alb_tg.arn
  }
}

# Create https listener for ALB
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_iam_server_certificate.elb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_alb_tg.arn
  }
}

# Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-ecs_cluster"
}

# Create ECS task definition
resource "aws_ecs_task_definition" "ecs_task" {
  family = "${var.project_name}-task"
  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = "${data.aws_ecr_repository.ecr_repo.repository_url}:latest"
      cpu       = 2
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])

  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  memory                   = 512
  cpu                      = 256

  execution_role_arn = aws_iam_role.ecs_exec.arn
}

# Create ECS Service and attach to ALB
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.project_name}-ecs"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    security_groups = [aws_security_group.ecs_sg.id]
    subnets = [
      data.aws_subnet.private1_subnet.id,
      data.aws_subnet.private2_subnet.id
    ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_alb_tg.arn
    container_name   = "${var.project_name}-container"
    container_port   = 3000
  }

}

# Create application scaling target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 1
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Lookup latest ECS AMI
data "aws_ami" "ecs" {
  most_recent = true # get the latest version

  filter {
    name = "name"
    values = [
    "amzn2-ami-ecs-*-x86_64*"] # ECS optimized image
  }

  filter {
    name = "virtualization-type"
    values = [
    "hvm"]
  }

  owners = [
    "amazon" # Only official images
  ]
}

# Create ASG Launch config for ECS EC2 instances
resource "aws_launch_configuration" "ecs_launch_config" {
  name                 = "${var.project_name}-ecs_ec2_asg_launch_config"
  image_id             = data.aws_ami.ecs.id
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.ecs_sg.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${var.project_name}-ecs_cluster >> /etc/ecs/ecs.config"
  instance_type        = "t3.micro"
}

# Create ASG for ECS EC2 instances
resource "aws_autoscaling_group" "ecs_ec2_asg" {
  name                 = "${var.project_name}-ecs_ec2_asg"
  vpc_zone_identifier  = [data.aws_subnet.private1_subnet.id, data.aws_subnet.private2_subnet.id]
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 10
  health_check_grace_period = 300
  health_check_type         = "EC2"
}
