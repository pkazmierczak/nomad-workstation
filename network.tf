data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
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
  vpc_id            = aws_vpc.nomad_test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone

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
