resource "aws_instance" "first_instance" {
  ami           = data.aws_ami.ubuntu_22.id
  instance_type = "t3.micro"

  tags = {
    Name = "first-instance"
  }
}
