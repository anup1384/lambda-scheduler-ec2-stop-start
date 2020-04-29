####### Please use terraform version v0.12  ###############


module "stop_ec2_instance" {
  source                         = "./lambda-scheduler-stop-start/"
  name                           = "ec2_stop"
  cloudwatch_schedule_expression = "cron(30 16 ? * MON-FRI *)"
  schedule_action                = "stop"
  ec2_schedule                   = "true"
  resources_tag                  = {
    key   = "schedule"
    value = "yes"
  }

tags = {
    environment    = "nonprod"
    techteam       = "TeamA"
    role           = "lambda"
  }

}

module "start_ec2_instance" {
  source                         = "./lambda-scheduler-stop-start/"
  name                           = "ec2_start"
  cloudwatch_schedule_expression = "cron(0 4 ? * MON-FRI *)"
  schedule_action                = "start"
  ec2_schedule                   = "true"
  resources_tag                  = {
    key   = "schedule"
    value = "yes"
  }

tags = {
    environment    = "nonprod"
    techteam       = "TeamA"
    role           = "lambda"
  }

}
