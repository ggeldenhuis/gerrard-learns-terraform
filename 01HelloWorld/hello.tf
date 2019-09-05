provider "aws" {
  profile    = "default"
  region     = "eu-west-2"
}

resource "aws_instance" "helloworld01" {
  ami             = "ami-00a1270ce1e007c27"
  instance_type   = "t2.micro"
}

#resource "aws_instance" "helloworld02" {
#  ami           = "ami-00a1270ce1e007c27"
#  instance_type = "t2.micro"
#}
