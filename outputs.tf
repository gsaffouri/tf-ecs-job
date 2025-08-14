output "run_hint" {
  value = "aws ecs run-task --cluster ${aws_ecs_cluster.this.name} --launch-type FARGATE --task-definition ${aws_ecs_task_definition.job.family} --network-configuration awsvpcConfiguration={subnets=[${join(",", formatlist("%q", data.aws_subnets.default_public.ids))}],securityGroups=[${aws_security_group.task.id}],assignPublicIp=ENABLED}"
}
