# Terraform & ECS FTW! 

Terraform-managed **ECS Fargate one-off job**: build/push an image to ECR, run it as a task on an ECS cluster, watch logs, and shut down to save 💸.

This repo is opinionated: minimal infra, fast deploys, and a clean “run it, finish, and exit” flow.


[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-5C4EE5)](#) [![AWS](https://img.shields.io/badge/AWS-ECS%20%7C%20ECR-FF9900)](#) [![IaC](https://img.shields.io/badge/IaC-Terraform-informational)](#)


```
+-------------------+             +----------------------+
|   Developer/CI    |  terraform  |        AWS           |
|  (local/Actions)  +------------>+  VPC/Subnets/SecGrp  |
+-------------------+             |        ECS Cluster   |
        |                         |  Task Definition     |
        |  docker build & push    |  CloudWatch Logs     |
        +------------------------>+  ECR Repository      |
                                  +----------------------+

Run flow:
1) terraform apply → creates ECS cluster, roles, log group, task def, (optionally ECR)
2) run_task.sh → aws ecs run-task --launch-type FARGATE
3) task runs → writes logs → exits → you only pay while it runs
```


## What This Stack Includes
- **ECS Fargate** — Serverless containers; zero EC2 to manage.
- **One-off Jobs** — Fire-and-forget tasks that terminate on completion.
- **CloudWatch Logs** — Centralized logs per task run.
- **Least-privilege IAM** — Separate execution role and task role.
- **ECR Integration** — Optional ECR repo for your image.

## Prerequisites
- Terraform installed (>= 1.5)
- AWS credentials configured (env vars or profile with rights to create ECS/ECR/IAM/Logs/VPC or access existing VPC)
- Docker installed if you build/push images locally
- `jq` installed if using `run_task.sh`

## Quickstart
```bash
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
# optional: build & push image to ECR, then update var `image` or task def
```
Then run a one-off task:
```bash
./run_task.sh   # or use the AWS Console → ECS → Clusters → Run task
```

## Repository Structure
```
└── tf-ecs-job-main
    ├── .gitignore
    ├── destroy.sh
    ├── LICENSE
    ├── main.tf
    ├── outputs.tf
    ├── README.md
    ├── run_task.sh
    └── variables.tf
```

## Key Files Explained
_None detected yet._

## Variables
_None detected yet._

## Outputs
_None detected yet._

## Logs & Debugging
- **ECS Console → Clusters → Tasks** to see running/stopped tasks and exit codes
- **CloudWatch Logs → Log groups** (from output `log_group_name`) for container stdout/stderr
- Common gotchas:
  - `jq: command not found` → `sudo apt-get install -y jq`
  - Stuck in `PROVISIONING` → subnet/SecGrp/VPC issues; ensure correct subnets and route to NAT/Internet as required
  - Task `ResourceInitializationError` → execution role missing ECR/Logs permissions
  - Image pull errors → wrong ECR repo/region or credentials

## Running the Job on a Schedule (Optional)
Use EventBridge to trigger the task definition on a cron. Add a rule + target (ECS RunTask) referencing your cluster and task definition.

## Clean Up
```bash
terraform destroy
# also delete ECR images if you created a repo
```

---
*Pro tip:* Don’t commit `.terraform/` or `*.tfstate*`. Keep `.terraform.lock.hcl` committed so your team uses the same provider versions.
