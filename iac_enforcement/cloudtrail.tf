resource "aws_cloudtrail" "iacenforcement" {
  name                          = "iac-enforcement"
  s3_bucket_name                = aws_s3_bucket.this.id
  include_global_service_events = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.iac_enforcement.arn}:*" # CloudTrail requires the Log Stream wildcard
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn


  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true
  }

}
