resource "aws_security_group" "ec2" {
  name   = "${local.name}-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "ec2" {
  name_prefix            = "${local.name}-lt-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf -y install python3 pip
    mkdir -p /opt/ec2-web
    cat >/etc/systemd/system/ec2-web.service <<SVC
    [Unit]
    Description=EC2 Web
    After=network.target
    [Service]
    WorkingDirectory=/opt/ec2-web
    ExecStart=/usr/bin/python3 /opt/ec2-web/app.py
    Restart=always
    [Install]
    WantedBy=multi-user.target
    SVC
    systemctl daemon-reload
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tags = local.tags
}

resource "aws_autoscaling_group" "ec2_blue" {
  name                = "${local.name}-ec2-blue"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [for s in aws_subnet.public : s.id]

  launch_template {
    id      = aws_launch_template.ec2.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.ec2_blue.arn]
  health_check_type = "EC2"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-ec2-blue"
    propagate_at_launch = true
  }
}

# ---------- GREEN ASG ----------
resource "aws_autoscaling_group" "ec2_green" {
  name                = "${local.name}-ec2-green"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [for s in aws_subnet.public : s.id]

  launch_template {
    id      = aws_launch_template.ec2.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.ec2_green.arn]
  health_check_type = "EC2"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-ec2-green"
    propagate_at_launch = true
  }
}