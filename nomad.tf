terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

resource "random_pet" "workstation" {
}

locals {
  random_name = "${var.cluster_name}-${random_pet.workstation.id}"
}

module "keys" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "v2.0.0"

  name = local.random_name
  path = "${path.root}/keys"
}

data "aws_ami" "ubuntu" {
  filter {
    name   = "name"
    values = [var.ami]
  }

  most_recent = true
  owners      = ["099720109477"] # Canonical
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "nomad_server" {
  count                  = var.server_count
  availability_zone      = var.zone
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.nomad_server_instance_type
  subnet_id              = aws_subnet.nomad_test_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = module.keys.key_name
  iam_instance_profile   = aws_iam_instance_profile.nomad_instance_profile.id

  user_data = (templatefile("${path.module}/userdata.sh", {
    nomad_conf = templatefile("${path.module}/nomad_server.hcl", {
      role   = "${var.cluster_name}_server"
      expect = "${var.server_count}"
    })
    ssh_private_key = file(pathexpand("${var.ssh_private_key}")),
    ssh_public_key  = file(pathexpand("${var.ssh_public_key}")),
  }))
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name       = "${var.cluster_name}_server_${count.index}"
    Nomad_role = "${var.cluster_name}_server"
  }
}

resource "aws_instance" "nomad_client" {
  count                       = var.client_count
  availability_zone           = var.zone
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.nomad_client_instance_type
  subnet_id                   = aws_subnet.nomad_test_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = module.keys.key_name
  iam_instance_profile        = aws_iam_instance_profile.nomad_instance_profile.id
  associate_public_ip_address = true

  user_data = (templatefile("${path.module}/userdata.sh", {
    nomad_conf = templatefile("${path.module}/nomad_client.hcl", {
      role = "${var.cluster_name}_server"
    })
    ssh_private_key = file(pathexpand("${var.ssh_private_key}")),
    ssh_public_key  = file(pathexpand("${var.ssh_public_key}")),
  }))
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name       = "${var.cluster_name}_client_${count.index}"
    Nomad_role = "${var.cluster_name}_client"
  }
}

output "message" {
  value = <<-EOM
ssh into servers with:
%{for ip in aws_eip.nomad_server_eip.*.public_ip~}
 ssh -i ${abspath(path.module)}/keys/${module.keys.key_name}.pem ubuntu@${ip}
%{endfor~}
ssh into clients with:
%{for ip in aws_instance.nomad_client.*.public_ip~}
 ssh -i ${abspath(path.module)}/keys/${module.keys.key_name}.pem ubuntu@${ip}
%{endfor~}
EOM
}
