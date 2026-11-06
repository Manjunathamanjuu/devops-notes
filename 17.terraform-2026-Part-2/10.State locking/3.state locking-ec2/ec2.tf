resource "aws_instance" "server" {
  ami           = "ami-04b4f1a9cf54c11d0"
  instance_type = "t3.micro"

  tags = {
    Name = "demo"
  }
}
