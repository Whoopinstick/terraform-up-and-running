resource "aws_instance" "first_instance" {
  ami           = data.aws_ami.ubuntu_22.id
  instance_type = "t3.micro"

  tags = {
    Name      = "first-instance"
    terraform = true
  }
}

resource "aws_instance" "second_instance_with_user_data" {
  ami             = data.aws_ami.ubuntu_22.id
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.sg_second_instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.xhtml
              nohup busybox http -f -p ${var.server_port} &
              EOF

  # if user_data changes, replace the instance
  user_data_replace_on_change = true

  tags = {
    Name      = "second-instance"
    terraform = true
  }

}

resource "aws_security_group" "sg_second_instance" {
  name = "sg_for_second_instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_launch_configuration" "third_instance_with_asg" {
  image_id        = data.aws_ami.ubuntu_22.id
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.sg_second_instance.id]
  user_data       = <<-EOF
#!/bin/bash
echo "Hello, World" > index.xhtml
nohup busybox httpd -f -p ${var.server_port} &
EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "asg_third_instance" {
  launch_configuration = aws_launch_configuration.third_instance_with_asg.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb.lb_third_instance.arn]
  health_check_type    = "ELB"

  min_size = 2
  max_size = 5
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "lb_third_instance" {
  name               = "asg-third-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.sg_alb.id]

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb_third_instance.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "sg_alb" {
  name = "third-example-alb-sg"
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
}

resource "aws_lb_target_group" "tg_asg_third_instance" {
  name     = "tg-sg-third-instance"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_asg_third_instance.arn
  }
}