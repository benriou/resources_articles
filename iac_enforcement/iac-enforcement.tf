## This is the module invocation 
## you might want to change the source folder depending where the module is located

module "iac_enforcement" {
  source              = "."
  logs_retention_days = 30
  monitored_role      = "enter_your_iam_role_here"
}
