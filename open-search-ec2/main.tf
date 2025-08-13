terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}


module "opensearch_ec2" {
  source = "../modules/opensearch_ec2"

  # EC2 infra
  ec2_instance_count     = var.ec2_instance_count
  ec2_instance_type      = var.ec2_instance_type
  ec2_ami_id             = var.ec2_ami_id
  ec2_subnet_ids         = var.ec2_subnet_ids
  ec2_key_name           = var.ec2_key_name
  ec2_security_group_ids = var.ec2_security_group_ids
  ec2_name_prefix        = var.ec2_name_prefix
  ec2_tags               = var.ec2_tags

  # EBS data volume for OpenSearch data path
  ec2_ebs_device_name           = var.ec2_ebs_device_name
  ec2_ebs_volume_size           = var.ec2_ebs_volume_size
  ec2_ebs_volume_type           = var.ec2_ebs_volume_type
  ec2_ebs_delete_on_termination = var.ec2_ebs_delete_on_termination
  ec2_ebs_encrypted             = var.ec2_ebs_encrypted

  # OpenSearch config
  os_cluster_name    = var.os_cluster_name
  os_version         = var.os_version
  os_http_port       = var.os_http_port
  os_transport_port  = var.os_transport_port
  os_heap            = var.os_heap
  os_enable_security = var.os_enable_security
  os_allow_cidr_http = var.os_allow_cidr_http
}
