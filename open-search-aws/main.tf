terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

module "opensearch" {
  source = "../modules/opensearch"

  # Pass-through inputs
  opensearch_domain_name                 = var.opensearch_domain_name
  opensearch_version                     = var.opensearch_version
  opensearch_instance_type               = var.opensearch_instance_type
  opensearch_instance_count              = var.opensearch_instance_count
  opensearch_zone_awareness_enabled      = var.opensearch_zone_awareness_enabled
  opensearch_az_count                    = var.opensearch_az_count
  opensearch_ebs_enabled                 = var.opensearch_ebs_enabled
  opensearch_ebs_volume_size             = var.opensearch_ebs_volume_size
  opensearch_ebs_volume_type             = var.opensearch_ebs_volume_type
  opensearch_vpc_subnet_ids              = var.opensearch_vpc_subnet_ids
  opensearch_security_group_ids          = var.opensearch_security_group_ids
  opensearch_tags                        = var.opensearch_tags
  opensearch_encrypt_at_rest_enabled     = var.opensearch_encrypt_at_rest_enabled
  opensearch_kms_key_id                  = var.opensearch_kms_key_id
  opensearch_node_to_node_encryption_enabled = var.opensearch_node_to_node_encryption_enabled
  opensearch_enforce_https               = var.opensearch_enforce_https
  opensearch_tls_security_policy         = var.opensearch_tls_security_policy
  opensearch_master_user_name            = var.opensearch_master_user_name
  opensearch_master_user_password        = var.opensearch_master_user_password
}

# Optional: expose module outputs at root
output "opensearch_domain_arn" {
  value       = module.opensearch.opensearch_domain_arn
  description = "ARN of the OpenSearch domain"
}

output "opensearch_endpoint" {
  value       = module.opensearch.opensearch_endpoint
  description = "OpenSearch HTTPS endpoint"
}

output "opensearch_dashboard_endpoint" {
  value       = module.opensearch.opensearch_dashboard_endpoint
  description = "Dashboards (Kibana) endpoint"
}
