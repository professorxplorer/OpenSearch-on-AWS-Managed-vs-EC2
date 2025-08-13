variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources."
}

# --- OpenSearch (pass-through to module) ---
variable "opensearch_domain_name" {
  type        = string
  default     = ""
  description = "Name of the OpenSearch domain."
}

variable "opensearch_version" {
  type        = string
  default     = "OpenSearch_2.13"
  description = "OpenSearch engine version."
}

variable "opensearch_instance_type" {
  type        = string
  default     = ""
  description = "Data node instance type (e.g., m6g.large.search)."
}

variable "opensearch_instance_count" {
  type        = number
  default     = 3
  description = "Number of data nodes."
}

variable "opensearch_zone_awareness_enabled" {
  type        = bool
  default     = false
  description = "Enable zone awareness for HA (requires 2/3 subnets across distinct AZs)."
}

variable "opensearch_az_count" {
  type        = number
  default     = 1
  description = "Number of AZs when zone awareness is enabled."
}

variable "opensearch_ebs_enabled" {
  type        = bool
  default     = true
  description = "Enable EBS for data nodes."
}

variable "opensearch_ebs_volume_size" {
  type        = number
  default     = 100
  description = "EBS volume size (GiB)."
}

variable "opensearch_ebs_volume_type" {
  type        = string
  default     = "gp3"
  description = "EBS volume type."
}

variable "opensearch_vpc_subnet_ids" {
  type        = list(string)
  default     = []
  description = "VPC subnet IDs (1, 2, or 3 subnets; one per AZ)."
}

variable "opensearch_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Security groups for the domain ENIs."
}

variable "opensearch_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the domain."
}

variable "opensearch_encrypt_at_rest_enabled" {
  type        = bool
  default     = true
  description = "Enable encryption at rest."
}

variable "opensearch_kms_key_id" {
  type        = string
  default     = ""
  description = "Optional KMS key ID; empty uses AWS-managed key."
}

variable "opensearch_node_to_node_encryption_enabled" {
  type        = bool
  default     = true
  description = "Enable node-to-node encryption."
}

variable "opensearch_enforce_https" {
  type        = bool
  default     = true
  description = "Force HTTPS for the domain endpoint."
}

variable "opensearch_tls_security_policy" {
  type        = string
  default     = "Policy-Min-TLS-1-2-2019-07"
  description = "TLS policy for the domain endpoint."
}

variable "opensearch_master_user_name" {
  type        = string
  default     = ""
  description = "Master user (optional; enables fine-grained access control if set with password)."
}

variable "opensearch_master_user_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Master user password (optional)."
}
