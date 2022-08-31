module "iac_enforcement_eu_west_1" {
  source                 = "./iac_enforcement_module"
  logs_retention_days    = 30
  monitored_role         = "ENTER_IAM_ROLE_HERE"
  sns_email_subscription = "email@email.com"
}

module "iac_enforcement_us_east_1" {
  providers = {
    aws = aws.us_east_1
  }
  source                 = "./iac_enforcement_module"
  logs_retention_days    = 30
  monitored_role         = "ENTER_IAM_ROLE_HERE"
  sns_email_subscription = "email@email.com"
}
