# Pre-provision Lambda and alias so CodeDeploy can do blue/green immediately.
# Ensure you have created apps/lambda-api/bootstrap.zip from your handler.py (local step).

resource "aws_lambda_function" "api" {
  function_name    = "${local.name}-lambda"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  filename         = "${path.module}/../apps/lambda-api/bootstrap.zip"
  source_code_hash = filebase64sha256("${path.module}/../apps/lambda-api/bootstrap.zip")
  tags             = local.tags
}

resource "aws_lambda_alias" "live" {
  name             = "Live"
  function_name    = aws_lambda_function.api.arn
  function_version = "$LATEST"
}