provider "aws" {
  profile    = "default"
  region     = "eu-west-2"
}

resource "aws_instance" "helloworld01" {
  ami             = "ami-00a1270ce1e007c27"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.glt-keypair.key_name}"
  security_groups = ["launch-wizard-5"]
}

resource "aws_key_pair" "glt-keypair" {
  public_key = "${file(pathexpand("~/.ssh/glt_rsa.pub"))}"
}
