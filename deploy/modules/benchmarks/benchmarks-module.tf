module "benchmarks_sns_topic" {
    source = "../sns"
    sns_topic_name = "${var.name_prefix}-sns-topic"
}
module "step_function" {
    source = "../step-function"
    count = var.enable_step_function ? 1 : 0
    name = "${var.name_prefix}-workflow"
    definition_file = var.step_fn_definition_file
    state_machine_definition_vars = {
        job_definition_name_on_demand = module.benchmarks_on_demand.batch_job_definition_name
        job_queue_on_demand = module.benchmarks_on_demand.batch_job_queue_name
        job_definition_name_spot = module.benchmarks_spot.batch_job_definition_name
        job_queue_spot = module.benchmarks_spot.batch_job_queue_name
        sns_topic_arn = module.benchmarks_sns_topic.arn
    }
}
module "benchmarks_on_demand" {
    source = "../batch"
    name_prefix = var.name_prefix
    subnet_ids = var.subnet_ids
    ami_id = var.ami_id
    instance_types = var.instance_types
    security_group_id = var.security_group_id
    timeout_seconds = var.timeout_seconds
    docker_image = var.docker_image
    container_cpu = var.container_cpu
    container_memory = var.container_memory
    container_properties_file = var.container_properties_file
    region = var.region
    log_retention_days = var.log_retention_days
    s3_path = var.s3_path
    ec2_key_pair = var.ec2_key_pair
    volume_size = var.volume_size
    shared_memory_size = var.shared_memory_size
    compute_type = "EC2"
    resolution = var.resolution
    num_cores_per_node = var.num_cores_per_node
    compute_resource_tags = {
        Name = "cloud-benchmarks-on-demand"
    }
}
module "benchmarks_spot" {
    source = "../batch"
    name_prefix = "${var.name_prefix}-spot"
    subnet_ids = var.subnet_ids
    ami_id = var.ami_id
    instance_types = var.instance_types
    security_group_id = var.security_group_id
    timeout_seconds = var.timeout_seconds
    docker_image = var.docker_image
    container_cpu = var.container_cpu
    container_memory = var.container_memory
    container_properties_file = var.container_properties_file
    region = var.region
    log_retention_days = var.log_retention_days
    s3_path = var.s3_path
    ec2_key_pair = var.ec2_key_pair
    volume_size = var.volume_size
    shared_memory_size = var.shared_memory_size
    resolution = var.resolution
    num_cores_per_node = var.num_cores_per_node
    allocation_strategy = "SPOT_CAPACITY_OPTIMIZED" # lowers chance of interruptions
    compute_resource_tags = {
        Name = "cloud-benchmarks-spot"
    }
}