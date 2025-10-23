resource "aws_codedeploy_app" "ec2" {
  name             = "${local.name}-ec2-app"
  compute_platform = "Server"
  tags             = local.tags
}

resource "aws_codedeploy_deployment_group" "ec2" {
  app_name               = aws_codedeploy_app.ec2.name
  deployment_group_name  = "${local.name}-ec2-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT" # or "STOP_DEPLOYMENT" with wait_time_in_minutes
    }
  }

  autoscaling_groups = [
    aws_autoscaling_group.ec2_blue.name,
    aws_autoscaling_group.ec2_green.name
  ]

  # EC2 blue/green uses target_group_info (NOT target_group_pair_info)
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.ec2_blue.name
    }
    target_group_info {
      name = aws_lb_target_group.ec2_green.name
    }
  }


  tags = local.tags
}
