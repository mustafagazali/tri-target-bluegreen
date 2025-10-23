resource "aws_codepipeline" "main" {
  name     = "${local.name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  # -------- Source (GitHub via CodeStar Connections) --------
  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  # -------- Build (parallel) --------
  stage {
    name = "Build"

    action {
      name             = "Build_Lambda"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["lambda_build"]
      configuration    = { ProjectName = aws_codebuild_project.lambda.name }
    }

    action {
      name             = "Build_ECS"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["ecs_build"]
      configuration    = { ProjectName = aws_codebuild_project.ecs.name }
    }

    action {
      name             = "Build_EC2"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["ec2_build"]
      configuration    = { ProjectName = aws_codebuild_project.ec2.name }
    }
  }

  # -------- Deploy --------
  stage {
    name = "Deploy"

    action {
      name            = "Deploy_Lambda"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["lambda_build"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.lambda.name
        DeploymentGroupName = aws_codedeploy_deployment_group.lambda.deployment_group_name
      }
    }

    action {
      name            = "Deploy_ECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["ecs_build"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.ecs.name
        DeploymentGroupName = aws_codedeploy_deployment_group.ecs.deployment_group_name
      }
    }

    action {
      name            = "Deploy_EC2"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["ec2_build"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.ec2.name
        DeploymentGroupName = aws_codedeploy_deployment_group.ec2.deployment_group_name
      }
    }
  }

  tags = local.tags
}
