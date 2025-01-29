data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_vpc" "nomad_test_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "${var.cluster_name}_vpc"
  }
}

resource "aws_internet_gateway" "nomad_test_igw" {
  vpc_id = aws_vpc.nomad_test_vpc.id

  tags = {
    Name = "${var.cluster_name}_igw"
  }
}

resource "aws_eip" "nomad_server_eip" {
  count    = var.server_count
  instance = "${element(aws_instance.nomad_server.*.id, count.index)}"
  vpc      = true

  tags = {
    Name = "${var.cluster_name}_server_eip_${count.index}"
  }
}

resource "aws_eip" "nomad_client_eip" {
  count    = var.client_count
  instance = "${element(aws_instance.nomad_client.*.id, count.index)}"
  vpc      = true

  tags = {
    Name = "${var.cluster_name}_client_eip_${count.index}"
  }
}

resource "aws_default_route_table" "nomad_test_route_table" {
  default_route_table_id = aws_vpc.nomad_test_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad_test_igw.id
  }

  tags = {
    Name = "${var.cluster_name}_route_table"
  }
}

resource "aws_subnet" "nomad_test_subnet" {
  vpc_id            = aws_vpc.nomad_test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone

  tags = {
    Name = "${var.cluster_name}_subnet"
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
    Name = "${var.cluster_name}_allow_ssh"
  }
}
