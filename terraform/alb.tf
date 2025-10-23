resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "ALB SG"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_lb" "app" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.alb.id]
  tags               = local.tags
}

resource "aws_lb_target_group" "ecs_blue" {
  name        = "${local.name}-ecs-blue"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/" }
  tags = local.tags
}

resource "aws_lb_target_group" "ecs_green" {
  name        = "${local.name}-ecs-green"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/" }
  tags = local.tags
}

resource "aws_lb_target_group" "ec2_blue" {
  name     = "${local.name}-ec2-blue"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/" }
  tags = local.tags
}

resource "aws_lb_target_group" "ec2_green" {
  name     = "${local.name}-ec2-green"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/" }
  tags = local.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "ok"
      status_code  = "200"
    }
  }
}

# Second listener for test traffic (any free port)
resource "aws_lb_listener" "http_test" {
  load_balancer_arn = aws_lb.app.arn
  port              = 9000
  protocol          = "HTTP"

  # simple default action; CodeDeploy will direct traffic to the right TGs
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "test listener"
      status_code  = "200"
    }
  }
}

# Path-based routing
resource "aws_lb_listener_rule" "ecs_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_blue.arn
  } # CodeDeploy will manage pair
  condition {
    path_pattern {
      values = ["/ecs/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ec2_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_blue.arn
  }
  condition {
    path_pattern {
      values = ["/ec2/*"]
    }
  }
}

# Attach GREEN TGs to the ALB so CodeDeploy accepts the pair

resource "aws_lb_listener_rule" "ecs_green_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_green.arn
  }
  condition {
    path_pattern { values = ["/ecs-green/*"] }
  }
}

resource "aws_lb_listener_rule" "ec2_green_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_green.arn
  }
  condition {
    path_pattern { values = ["/ec2-green/*"] }
  }
}
