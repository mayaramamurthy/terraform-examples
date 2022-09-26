terraform {
  cloud {
    organization = "MayaTerraform"

    workspaces {
      name = "provisioners"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "main" {
  id = "vpc-063ebaf697e64f210"
}

data "template_file" "user_data" {
  template = file("./userdata.yaml")
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "<my ssh-key>"
}
resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "MyServer Security Group"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description      = "HTTP "
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
  ingress {
    description      = "SSH "
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["72.141.96.70/32"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  egress {
    description      = "outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

}
resource "aws_instance" "my_server" {
  ami                    = "ami-026b57f3c383c2eec"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.sg_my_server.id]
  user_data              = data.template_file.user_data.rendered

  provisioner "remote-exec" {
    inline = [
      "echo ${self.private_ip} >> /home/ec2-user/private_ips.txt"
    ]
  }

  tags = {
    Name = "MyServer"
  }
}


output "public_ip" {
  value = aws_instance.my_server.public_ip
}