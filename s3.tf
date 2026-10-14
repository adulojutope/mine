resource "aws_s3_bucket" "lb_logs" {
  bucket        = "my-demo-lb-logs-84372704"   # must be globally unique across all of AWS
  force_destroy = true                      # lets terraform destroy delete the bucket even if it has log files
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = data.aws_elb_service_account.main.arn }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.lb_logs.arn}/demo-lb/AWSLogs/*"
    }]
  })
}