terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- Networking: use default VPC and its public subnets to avoid NAT costs ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group: egress only
resource "aws_security_group" "task" {
  name        = "${var.project}-task-sg"
  description = "Egress-only for Fargate task"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Project = var.project }
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7
}

# --- IAM roles (execution + task) ---
data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "execution" {
  name               = "${var.project}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

# Allow pulling from ECR + writing logs
resource "aws_iam_role_policy_attachment" "exec_ecr" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.project}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

# Add app-specific perms here if your job needs AWS access

# --- ECS Cluster ---
resource "aws_ecs_cluster" "this" {
  name = var.project
}

# --- Task Definition (Fargate) ---
resource "aws_ecs_task_definition" "job" {
  family                   = "${var.project}-job"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "job"
      image     = var.container_image   # e.g. public.ecr.aws/docker/library/busybox:latest
      essential = true
      command   = var.command           # e.g. ["sh","-c","echo hello; sleep 5"]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# We won't create a Service (keeps it truly one-shot). We'll run tasks on demand.

output "cluster_name"          { value = aws_ecs_cluster.this.name }
output "task_definition_arn"   { value = aws_ecs_task_definition.job.arn }
output "security_group_id"     { value = aws_security_group.task.id }
output "subnet_ids"            { value = data.aws_subnets.default_public.ids }
output "log_group"             { value = aws_cloudwatch_log_group.this.name }
