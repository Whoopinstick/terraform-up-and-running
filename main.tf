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
              nohup busybox http -f -p 8080 &
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
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}