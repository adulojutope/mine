# This file contains the launch template for the application tier of the demo application. The launch template is used by the auto scaling group to launch EC2 instances.

resource "aws_launch_template" "demo" {
  name_prefix            = "demo-app-"
  image_id               = data.aws_ami.amzn2.id
  instance_type          = "t3.micro"
  key_name               = local.projectlamp
  vpc_security_group_ids = [aws_security_group.apptier.id]

  user_data = base64encode(templatefile("${path.module}/app.sh.tpl", {
    efs_dns = aws_efs_file_system.demo.dns_name
    # db_host     = aws_db_instance.demo.address
    # db_name     = aws_db_instance.demo.db_name
    # db_user     = aws_db_instance.demo.username
    # db_password = aws_db_instance.demo.password
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "app-asg" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

## This file contains the auto scaling group for the application tier of the demo application. The auto scaling group is used to launch and terminate EC2 instances based on the desired capacity and health checks.

resource "aws_autoscaling_group" "demo" {
  name                = "demo-app-asg"
  min_size            = 2
  desired_capacity    = 2
  max_size            = 4
  vpc_zone_identifier = [aws_subnet.private_subnet_apptier1.id, aws_subnet.private_subnet_apptier2.id]

  target_group_arns         = [aws_lb_target_group.demo_listener.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 900

  launch_template {
    id      = aws_launch_template.demo.id
    version = aws_launch_template.demo.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  depends_on = [
    aws_nat_gateway.demo-nat-gateway1,
    aws_route_table_association.association_private_subnet_apptier,
     aws_efs_mount_target.demo,                               
    aws_instance.bootstrap,
  ]
}

## This file contains the auto scaling policy for the application tier of the demo application. The auto scaling policy is used to adjust the capacity of the auto scaling group based on CPU utilization.
resource "aws_autoscaling_policy" "cpu" {
  name                   = "cpu-target-50"
  autoscaling_group_name = aws_autoscaling_group.demo.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
#Using reequest count per target metric for scaling based on ALB request count per target

#     predefined_metric_specification {
#   predefined_metric_type = "ALBRequestCountPerTarget"
#   resource_label         = "${aws_lb.demo.arn_suffix}/${aws_lb_target_group.demo_listener.arn_suffix}"
#     }
#   target_value = 100

  }
}

