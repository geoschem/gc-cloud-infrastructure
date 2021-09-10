module "ecs_service_user" {
    source = "../iam/user"

    name = "${var.ecs_name_prefix}-service-user"
    permitted_services = "\"s3:*\", \"sts:*\", \"ecs:*\""
}

resource "aws_ecs_cluster" "cluster" {
    name = "${var.ecs_name_prefix}-cluster"
}

resource "aws_ecs_service" "service" {
    name = "${var.ecs_name_prefix}-service"
    cluster = aws_ecs_cluster.cluster.arn
    task_definition = aws_ecs_task_definition.benchmarks_cloud_task.arn
    desired_count = 0
    launch_type = "EC2"

    network_configuration {
      security_groups = [var.security_group_id]
      subnets = var.subnet_ids
    #   assign_public_ip = "true"
    }
}

resource "aws_ecs_task_definition" "benchmarks_cloud_task" {
  family = "${var.ecs_name_prefix}-task"
  execution_role_arn = aws_iam_role.ecs_benchmarks_cloud_role.arn # created in role.tf
#   task_role_arn = aws_iam_role.ecs_benchmarks_cloud_role.arn # maybe don't need both of these
  network_mode = "awsvpc"
  requires_compatibilities = ["EC2"]
#   cpu = var.cpu
#   memory = var.memory
  container_definitions = data.template_file.task_definition.rendered
}

data "template_file" "task_definition" {
  template = file(var.task_definition_file)

  vars = {
    cluster_name = "${var.ecs_name_prefix}-cluster"
    task_definition_name = "${var.ecs_name_prefix}-task"
    default_region = var.region
    docker_image = var.docker_image
    container_port = 3000 # TODO - port number?
    container_cpu = var.cpu
    container_memory = var.memory
    service_user_key = module.ecs_service_user.access_key
    service_user_secret = module.ecs_service_user.secret_access_key
  }
}

# logging 
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/ecs/${var.ecs_name_prefix}-cluster"
  retention_in_days = 30
}