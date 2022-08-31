resource "aws_iam_role" "iam_for_lambda" {
  name = "iam-for-lambda-iac-enforcement-${data.aws_region.current.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "test_policy" {
  name = "sns-publish"
  role = aws_iam_role.iam_for_lambda.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "iam:ListAccountAliases",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


data "archive_file" "zip_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_cloudwatch_log_group" "lambda_iac" {
  name              = "/aws/lambda/${aws_lambda_function.notification_lambda.function_name}"
  retention_in_days = var.logs_retention_days
}

resource "aws_lambda_function" "notification_lambda" {
  filename      = data.archive_file.zip_lambda.output_path
  function_name = "lambda_iac_alerting"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.lambda_handler"
  timeout       = 300

  source_code_hash = data.archive_file.zip_lambda.output_base64sha256

  runtime = "python3.9"


  environment {
    variables = {
      SNS_TOPIC_ARN  = "${aws_sns_topic.alert_sre.arn}"
      MONITORED_ROLE = var.monitored_role
    }
  }

  depends_on = [data.archive_file.zip_lambda]

}

resource "aws_lambda_function_event_invoke_config" "errors_notifications" {
  function_name = aws_lambda_function.notification_lambda.function_name
  qualifier     = "$LATEST"

  destination_config {
    on_failure {
      destination = aws_sns_topic.alert_sre.arn
    }

  }
}

resource "aws_cloudwatch_event_rule" "iac_alerting" {
  name          = "iac_enforcement_alarm"
  description   = "IAC enforcement alarm"
  event_pattern = <<EOF
{
  "source": [
    "aws.cloudwatch"
  ],
  "detail-type": [
    "CloudWatch Alarm State Change"
  ],
  "resources": [
    "${aws_cloudwatch_metric_alarm.this.arn}"
  ],
  "detail": {
    "state": {
      "value": [ "ALARM" ]
     }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "iac_alerting" {
  rule      = aws_cloudwatch_event_rule.iac_alerting.name
  target_id = "iac_alerting"
  arn       = aws_lambda_function.notification_lambda.arn
}

resource "aws_lambda_permission" "cloudwatch_invokations" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iac_alerting.arn
}
