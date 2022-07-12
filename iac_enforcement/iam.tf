resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail-iac-enforcement"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "cloudtrail"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream"
          ],
          Resource = [
            "${aws_cloudwatch_log_group.iac_enforcement.arn}:log-stream:*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:PutLogEvents"
          ],
          Resource = [
            "${aws_cloudwatch_log_group.iac_enforcement.arn}:log-stream:*"
          ]
        }
      ]
    })
  }
}
