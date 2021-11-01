
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "template_file" "component" {
    template = file(var.component_file)
}
resource "aws_imagebuilder_component" "component" {
    name = var.component_name
    platform = var.component_platform
    version = var.component_version
    data = data.template_file.component.rendered
    description = "Installs spack, sets up a compiler, and installs an environment from a remote manifest file."
}

resource "aws_imagebuilder_image_recipe" "recipe" {
  block_device_mapping {
    device_name = "/dev/xvdb"

    ebs {
      delete_on_termination = true
      volume_size           = 200
      volume_type           = "gp2"
    }
  }

  component {
    component_arn = aws_imagebuilder_component.component.arn
  }

  name         = var.recipe_name
  parent_image = "arn:${data.aws_partition.current.partition}:imagebuilder:${data.aws_region.current.name}:aws:image/amazon-linux-2-x86/x.x.x"
  version      = "1.0.1"
  lifecycle { create_before_destroy = true }
}

resource "aws_imagebuilder_image_pipeline" "pipeline" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.config.arn
  name                             = "${var.name_prefix}-pipeline"
  depends_on = [
    aws_imagebuilder_image_recipe.recipe
  ]
}

resource "aws_imagebuilder_infrastructure_configuration" "config" {
  instance_profile_name         = aws_iam_instance_profile.ec2_profile.name
  instance_types                = ["t2.nano", "t3.micro"]
  name                          = "${var.name_prefix}-config"
  security_group_ids            = [var.security_group_id]
  subnet_id                     = var.subnet_id
  terminate_instance_on_failure = true
}