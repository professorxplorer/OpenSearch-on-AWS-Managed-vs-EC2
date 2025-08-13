# EC2 inputs
variable "ec2_instance_count" {
  type = number
}

variable "ec2_instance_type" {
  type = string
}

variable "ec2_ami_id" {
  type = string
}

variable "ec2_subnet_ids" {
  type = list(string)
}

variable "ec2_key_name" {
  type = string
}

variable "ec2_security_group_ids" {
  type = list(string)
}

variable "ec2_name_prefix" {
  type = string
}

variable "ec2_tags" {
  type = map(string)
}

# EBS (data) inputs
variable "ec2_ebs_device_name" {
  type = string
}

variable "ec2_ebs_volume_size" {
  type = number
}

variable "ec2_ebs_volume_type" {
  type = string
}

variable "ec2_ebs_delete_on_termination" {
  type = bool
}

variable "ec2_ebs_encrypted" {
  type = bool
}

# OpenSearch settings
variable "os_cluster_name" {
  type = string
}

variable "os_version" {
  type = string
}

variable "os_http_port" {
  type = number
}

variable "os_transport_port" {
  type = number
}

variable "os_heap" {
  type = string
}

variable "os_enable_security" {
  type = bool
}

variable "os_allow_cidr_http" {
  type = list(string)
}
