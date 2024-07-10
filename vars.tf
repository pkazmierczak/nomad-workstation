variable "cluster_name" {
  description = "Used to name various infrastructure components"
  default     = "nomad-workstation"
}

variable "region" {
  description = "The AWS region to deploy to."
  default     = "eu-central-1"
}

variable "zone" {
  description = "The AWS AZ to deploy to."
  default     = "eu-central-1b" # eu-central-1a does not have c7a.xlarge instances
}

variable "nomad_server_instance_type" {
  description = "The AWS instance type to use for servers."
  default     = "c7a.2xlarge"
}

variable "nomad_client_instance_type" {
  description = "The AWS instance type to use for clients."
  default     = "m4.large"
}

variable "server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "client_count" {
  description = "The number of Ubuntu clients to provision."
  default     = "3"
}

variable "ami" {
  description = "AMI to use for Ubuntu machines."
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240423"
}

variable "ssh_private_key" {
  description = "Path to the private SSH key (for git usage)"
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_public_key" {
  description = "Path to the public SSH key (for git usage)"
  default     = "~/.ssh/id_ed25519.pub"
}
