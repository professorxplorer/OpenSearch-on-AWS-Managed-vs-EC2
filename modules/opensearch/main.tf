terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  use_fgac = var.opensearch_master_user_name != "" && var.opensearch_master_user_password != ""
}

resource "aws_opensearch_domain" "this" {
  domain_name    = var.opensearch_domain_name
  engine_version = var.opensearch_version

  cluster_config {
    instance_type          = var.opensearch_instance_type
    instance_count         = var.opensearch_instance_count
    zone_awareness_enabled = var.opensearch_zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.opensearch_zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.opensearch_az_count
      }
    }

    dedicated_master_enabled = false
  }

  ebs_options {
    ebs_enabled = var.opensearch_ebs_enabled
    volume_size = var.opensearch_ebs_volume_size
    volume_type = var.opensearch_ebs_volume_type
  }

  vpc_options {
    subnet_ids         = var.opensearch_vpc_subnet_ids
    security_group_ids = var.opensearch_security_group_ids
  }

  encrypt_at_rest {
    enabled    = var.opensearch_encrypt_at_rest_enabled
    kms_key_id = var.opensearch_kms_key_id != "" ? var.opensearch_kms_key_id : null
  }

  node_to_node_encryption {
    enabled = var.opensearch_node_to_node_encryption_enabled
  }

  domain_endpoint_options {
    enforce_https       = var.opensearch_enforce_https
    tls_security_policy = var.opensearch_tls_security_policy
  }

  advanced_security_options {
    enabled                        = local.use_fgac
    internal_user_database_enabled = local.use_fgac

    dynamic "master_user_options" {
      for_each = local.use_fgac ? [1] : []
      content {
        master_user_name     = var.opensearch_master_user_name
        master_user_password = var.opensearch_master_user_password
      }
    }
  }

  tags = var.opensearch_tags

  lifecycle {
    precondition {
      condition     = var.opensearch_domain_name != ""
      error_message = "opensearch_domain_name must be set."
    }
    precondition {
      condition     = var.opensearch_instance_type != ""
      error_message = "opensearch_instance_type must be set."
    }
    precondition {
      condition     = length(var.opensearch_vpc_subnet_ids) >= (var.opensearch_zone_awareness_enabled ? var.opensearch_az_count : 1)
      error_message = "Provide at least ${var.opensearch_az_count} subnets (in distinct AZs) when zone awareness is enabled."
    }
  }
}
