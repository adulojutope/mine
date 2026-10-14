

locals {
  projectlamp = "demo1"   # or "gbbbg.click" for the root domain
}



data "aws_ami" "amzn2" {
    most_recent = true
    owners      = ["amazon"]
    filter {
      name   = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

# ---------- 1. Bootstrap host (public subnet) ----------
resource "aws_instance" "bootstrap" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.webtier.id, aws_security_group.apptier.id]
  associate_public_ip_address = true
  key_name                    = local.projectlamp

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/bootstrap.sh.tpl", {
    efs_dns     = aws_efs_file_system.demo.dns_name
    db_host     = aws_db_instance.demo.address   # hostname only, no :3306
    db_name     = aws_db_instance.demo.db_name
    db_user     = aws_db_instance.demo.username
    db_password = aws_db_instance.demo.password
  })

  user_data_replace_on_change = true
  depends_on = [aws_efs_mount_target.demo, aws_db_instance.demo]

    
  tags = {
    Name = "efs-bootstrap"
  }
}

# ---------- 2 & 3. App servers (one per app tier subnet) ----------
resource "aws_instance" "app" {
  for_each = {
    app_1 = aws_subnet.private_subnet_apptier1.id
    app_2 = aws_subnet.private_subnet_apptier2.id
  }

  ami                    = data.aws_ami.amzn2.id
  instance_type          = "t3.micro"
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.apptier.id]
  key_name               = local.projectlamp

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

   user_data = templatefile("${path.module}/app.sh.tpl", {
    efs_dns = aws_efs_file_system.demo.dns_name
  })

  user_data_replace_on_change = true

  # Bootstrap host creates /html on EFS first; mount targets must exist
  depends_on = [aws_instance.bootstrap, aws_efs_mount_target.demo]

  tags = {
    Name = "app-${each.key}"
  }
}

# Register the app servers with the ALB target group
resource "aws_lb_target_group_attachment" "app" {
  for_each         = aws_instance.app
  target_group_arn = aws_lb_target_group.demo_listener.arn
  target_id        = each.value.id
  port             = 80
}

