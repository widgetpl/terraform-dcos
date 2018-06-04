variable "ssh_key_name" {
  description = "ssh key name associated with your instances for login"
  default = "DCOS_KEY"
}

variable "ssh_private_key_filename" {
 # cannot leave this empty as the file() interpolation will fail later on for the private_key local variable
 # https://github.com/hashicorp/terraform/issues/15605
 default = "./DCOS_KEY.pem"
 description = "Path to file containing your ssh private key"
}

variable "user" {
  description = "Username of the OS"
  default = "centos"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  default     = "default"
}

variable "admin_cidr" {
  description = "Inbound Master Access"
  default     = "0.0.0.0/0"
}

variable "os" {
  default = "centos_7.4"
  description = "Recommended DC/OS OSs are centos_7.2, coreos_1235.9.0, coreos_835.13.0"
}

variable "aws_master_instance_type" {
  description = "AWS DC/OS master instance type"
  default = "m3.xlarge"
}

variable "aws_master_instance_disk_size" {
  description = "AWS DC/OS Master instance type default size of the root disk (GB)"
  default = "60"
}

variable "aws_agent_instance_type" {
  description = "AWS DC/OS Private Agent instance type"
  default = "m3.xlarge"
}

variable "aws_agent_instance_disk_size" {
  description = "AWS DC/OS Private Agent instance type default size of the root disk (GB)"
  default = "60"
}

variable "aws_public_agent_instance_type" {
  description = "AWS DC/OS Public instance type"
  default = "m3.xlarge"
}

variable "aws_public_agent_instance_disk_size" {
  description = "AWS DC/OS Public instance type default size of the root disk (GB)"
  default = "60"
}

variable "aws_bootstrap_instance_type" {
  description = "AWS DC/OS Bootstrap instance type"
  default = "m3.large"
}

variable "aws_bootstrap_instance_disk_size" {
  description = "AWS DC/OS bootstrap instance type default size of the root disk (GB)"
  default = "60"
}

variable "num_of_private_agents" {
  description = "DC/OS Private Agents Count"
  default = 2
}

variable "num_of_public_agents" {
  description = "DC/OS Public Agents Count"
  default = 1
}

variable "num_of_masters" {
  description = "DC/OS Master Nodes Count (Odd only)"
  default = 3
}

variable "owner" {
  description = "Paired with Cloud Cluster Cleaner will notify on expiration via slack. Default is whoami. Can be overwritten by setting the value here"
  default = "demo"
}

variable "expiration" {
  description = "Paired with Cloud Cluster Cleaner will notify on expiration via slack"
  default = "1h"
}

variable "instance_disk_size" {
 description = "Default size of the root disk (GB)"
 default = "128"
}
