resource "aws_efs_file_system" "demo" {
  creation_token   = "demo-efs"
#   encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  tags = {
    Name = "demo-efs"
  }
}

resource "aws_efs_mount_target" "demo" {
  for_each = {
    app_1 = aws_subnet.private_subnet_apptier1.id
    app_2 = aws_subnet.private_subnet_apptier2.id
  }

  file_system_id  = aws_efs_file_system.demo.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}