resource "aws_ecr_repository" "ecs" {
  name                 = "${local.name}-repo"
  image_tag_mutability = "MUTABLE"
  tags                 = local.tags
}