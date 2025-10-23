# Artifact bucket for CodePipeline/CodeBuild
resource "random_id" "sfx" {
  byte_length = 3
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name}-artifacts-${random_id.sfx.hex}"
  force_destroy = true
  tags          = local.tags
}

# ---------- CodeBuild: Lambda ----------
resource "aws_codebuild_project" "lambda" {
  name         = "${local.name}-build-lambda"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

# ---------- CodeBuild: ECS ----------
resource "aws_codebuild_project" "ecs" {
  name         = "${local.name}-build-ecs"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_URI"
      value = aws_ecr_repository.ecs.repository_url
    }

    environment_variable {
      name  = "ECS_FAMILY"
      value = aws_ecs_task_definition.web.family
    }

    environment_variable {
      name  = "AWS_ECS_EXEC_ROLE_ARN"
      value = aws_iam_role.ecs_execution.arn
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}

# ---------- CodeBuild: EC2 ----------
resource "aws_codebuild_project" "ec2" {
  name         = "${local.name}-build-ec2"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = local.tags
}
