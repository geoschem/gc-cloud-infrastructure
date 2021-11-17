resource "aws_batch_compute_environment" "batch_environment" {
    compute_environment_name_prefix = "${var.name_prefix}-batch-environment-"
    compute_resources {
        instance_role = aws_iam_instance_profile.ec2_profile.arn
        instance_type = var.instance_types
        image_id = var.ami_id # ami to use
        max_vcpus = 1024
        security_group_ids = [
            var.security_group_id
        ]
        subnets = var.subnet_ids
        type = var.compute_type
        spot_iam_fleet_role = var.compute_type == "SPOT" ? aws_iam_role.spot_fleet_role[0].arn : null
    }
    service_role = aws_iam_role.batch_role.arn
    type = "MANAGED"
    lifecycle {
        create_before_destroy = true
    }
    # prevents race condition that causes failure to delete compute environment
    depends_on = [aws_iam_role_policy_attachment.batch_policy_attachment]
}

resource "aws_batch_job_queue" "job_queue" {
    name = "${var.name_prefix}-job-queue"
    state = "ENABLED"
    priority = 1
    compute_environments = [
        aws_batch_compute_environment.batch_environment.arn
    ]
    depends_on = [aws_batch_compute_environment.batch_environment]
}

resource "aws_batch_job_definition" "job" {
    name = "${var.name_prefix}-batch-job"
    type = var.job_type
    parameters = {}
    timeout {
        attempt_duration_seconds = var.timeout_seconds
    }
    container_properties = data.template_file.container_properties.rendered
}

data "template_file" "container_properties" {
    template = file(var.container_properties_file)

    vars = {
        default_region = var.region
        docker_image = var.docker_image
        container_cpu = var.container_cpu
        container_memory = var.container_memory
        job_role = aws_iam_role.job_role.arn
        log_group = var.name_prefix
        log_name = "${var.name_prefix}-batch-job"
        s3_path = var.s3_path
    }
}

# logging 
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/aws/batch/${var.name_prefix}"
  retention_in_days = var.log_retention_days
}
