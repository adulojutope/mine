resource "aws_lb" "demo" {
  name               = "demo-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webtier.id]
  subnets            =  [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "demo-lb"
    enabled = true
  }

  tags = {
    Environment = "dev"
  }

  depends_on = [aws_s3_bucket_policy.lb_logs]
}

# ***********************



resource "aws_lb_target_group" "demo_listener" {
  name        = "demo-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.demo.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

// ***********************


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.demo.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo_listener.arn
  }
  depends_on = [aws_acm_certificate.cert]
}

// *********************** certificate

# HTTP -> HTTPS redirect (optional)
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.demo.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# DNS record pointing the domain to the ALB
resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.domain
  type    = "A"

  alias {
    name                   = aws_lb.demo.dns_name
    zone_id                = aws_lb.demo.zone_id
    evaluate_target_health = true
  }
}

locals {
  domain = "app.gbbbg.click"   # or "gbbbg.click" for the root domain
}

# Finds the existing hosted zone in Route 53
data "aws_route53_zone" "main" {
  name         = "gbbbg.click"
  private_zone = false
}

# Requests the certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = local.domain
  validation_method = "DNS"

  tags = {
    Environment = "dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Creates the CNAME record that proves you own the domain
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Waits until ACM validates the record and issues the certificate
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}