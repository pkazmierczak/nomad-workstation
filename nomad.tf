terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

module "keys" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "v2.0.0"

  name = "nomad-workstation"
  path = "${path.root}/keys"
}

data "aws_ami" "ubuntu" {
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240126"]
  }

  most_recent = true
  owners      = ["099720109477"] # Canonical
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "nomad_test_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "nomad_test_vpc"
  }
}

resource "aws_internet_gateway" "nomad_test_igw" {
  vpc_id = aws_vpc.nomad_test_vpc.id

  tags = {
    Name = "nomad_test_igw"
  }
}

resource "aws_default_route_table" "nomad_test_route_table" {
  default_route_table_id = aws_vpc.nomad_test_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad_test_igw.id
  }

  tags = {
    Name = "nomad_test_route_table"
  }
}

resource "aws_subnet" "nomad_test_subnet" {
  vpc_id     = aws_vpc.nomad_test_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "nomad_test_subnet"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.nomad_test_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    from_port   = 60000
    to_port     = 61000
    protocol    = "udp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    from_port   = 4646
    to_port     = 4646
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "nomad_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c5.xlarge"
  # instance_type               = "c5n.metal"  # for NUMA testing
  subnet_id                   = aws_subnet.nomad_test_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = module.keys.key_name
  associate_public_ip_address = true
  user_data = (templatefile("${path.module}/userdata.sh", {
    NOMAD_CONF      = file("${path.module}/nomad_server.hcl")
    SSH_PRIVATE_KEY = file("/Users/piotrkazmierczak/.ssh/id_ed25519"),
    SSH_PUBLIC_KEY  = file("/Users/piotrkazmierczak/.ssh/id_ed25519.pub"),
  }))
  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "nomad_server"
  }
}

variable "client_names" {
  default = ["nomad_client1", "nomad_client2"]
}

resource "aws_instance" "nomad_client" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "m5.large"
  subnet_id                   = aws_subnet.nomad_test_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = module.keys.key_name
  associate_public_ip_address = true
  user_data = (templatefile("${path.module}/userdata.sh", {
    NOMAD_CONF = templatefile("${path.module}/nomad_client.hcl", {
      NOMAD_SERVER = aws_instance.nomad_server.private_ip
    })
    SSH_PRIVATE_KEY = file("/Users/piotrkazmierczak/.ssh/id_ed25519"),
    SSH_PUBLIC_KEY  = file("/Users/piotrkazmierczak/.ssh/id_ed25519.pub"),
  }))
  root_block_device {
    volume_size = 20
  }

  for_each = toset(var.client_names)
  tags = {
    Name = each.value
  }
}

output "nomad_server_public_ip" {
  description = "Nomad server public IP"
  value       = aws_instance.nomad_server.public_ip
}
output "nomad_client_public_ips" {
  description = "Nomad client public IPs"
  value       = { for k, v in aws_instance.nomad_client : k => v.public_ip }
}
