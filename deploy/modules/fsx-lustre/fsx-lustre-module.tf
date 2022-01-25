resource "aws_fsx_lustre_file_system" "fsx" {
  storage_capacity = 1200
  subnet_ids       = [var.subnet_ids]
  security_group_ids = var.security_group_ids
  import_path = var.import_path
}
