variable "project" {
  type    = string
  default = "ecs-one-shot"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# Any Docker image that can run headless. Start with busybox or alpine.
variable "container_image" {
  type        = string
  description = "Container image for the job"
  default     = "public.ecr.aws/docker/library/busybox:latest"
}

# The command your job should run (override later)
variable "command" {
  type        = list(string)
  default     = ["sh","-c","echo 'Hello from ECS Fargate'; sleep 5; echo done"]
}

# Fargate sizes: 256/512/1024/2048 CPU; memory 512..30720 MB (match combos)
variable "cpu" {
  type    = number
  default = 256   # .25 vCPU
}

variable "memory" {
  type    = number
  default = 512   # MB
}
