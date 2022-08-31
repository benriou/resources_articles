
#################
# CloudWatch part
#################

resource "aws_cloudwatch_log_metric_filter" "manual_changes" {
  name = "Non IAC Changes"
  pattern = replace(<<EOT
{
($.userIdentity.sessionContext.sessionIssuer.userName = "${var.monitored_role}" ) &&
($.userAgent != "*Confidence*") &&
($.userAgent != "*Terraform*") &&
($.userAgent != "*ssm-agent*") &&
($.eventName != "AssumeRole") &&
($.eventName != "StartQuery") &&
($.eventName != "ConsoleLogin") &&
($.eventName != "StartSession") &&
($.eventName != "CreateSession") &&
($.eventName != "ResumeSession") &&
($.eventName != "SendSSHPublicKey") &&
($.eventName != "PutCredentials") &&
($.managementEvent is true) &&
($.readOnly is false)
}
EOT
  , "\n", " ") # This field cannot exceed 1024 caracters

  log_group_name = aws_cloudwatch_log_group.iac_enforcement.name

  metric_transformation {
    name          = "Non IAC Changes"
    namespace     = "iac-enforcement"
    unit          = "Count"
    default_value = "0"
    value         = "1"

  }
}


resource "aws_cloudwatch_dashboard" "iac_enforcement" {
  dashboard_name = "iac-enforcement"
  dashboard_body = jsonencode(
    {
      widgets = [
        {
          height = 7
          properties = {
            legend               = { position = "right" }
            metrics              = [["iac-enforcement", "Non IAC Changes", { color = "#d62728" }]]
            region               = "eu-west-1"
            setPeriodToTimeRange = true
            stacked              = true
            view                 = "timeSeries"
            period               = 60
            stat                 = "Sum"
          }
          type  = "metric"
          width = 24
          x     = 0
          y     = 0
        },
        {
          height = 13
          properties = {
            query   = <<-EOT
                  SOURCE 'iac-enforcement' | fields @timestamp, userIdentity.principalId, eventName, @message
                  | sort @timestamp desc
                  | filter userIdentity.sessionContext.sessionIssuer.userName like /${var.monitored_role}/
                  | filter userAgent not like /Confidence/
                  | filter userAgent not like /Terraform/
                  | filter userAgent not like /ssm-agent/
                  | filter eventName not like /AssumeRole/
                  | filter eventName not like /ConsoleLogin/
                  | filter eventName not like /StartSession/
                  | filter eventName not like /CreateSession/
                  | filter eventName not like /ResumeSession/
                  | filter eventName not like /SendSSHPublicKey/
                  | filter eventName not like /PutCredentials/
                  | filter eventName not like /StartQuery/
                  | filter managementEvent = 1
                  | filter readOnly = 0
                  | limit 100
              EOT
            region  = "eu-west-1"
            stacked = false
            view    = "table"
          }
          type  = "log"
          width = 24
          x     = 0
          y     = 7
        },
      ]
    }
  )


}


resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name                = "Non-IAC changes detected"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = aws_cloudwatch_log_metric_filter.manual_changes.metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.manual_changes.metric_transformation[0].namespace
  period                    = "30"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "Non-IAC changes detected on the AWS account"
  alarm_actions             = [aws_sns_topic.alert_sre.arn]
  insufficient_data_actions = []
}


resource "aws_cloudwatch_log_group" "iac_enforcement" {
  name              = "iac-enforcement"
  retention_in_days = 30
}
