aws_region = "us-east-1"

# ---- OpenSearch Domain Configuration ----
opensearch_domain_name    = "opensearch-nonprod"
opensearch_version        = "OpenSearch_2.13"
opensearch_instance_type  = "m6g.large.search"
opensearch_instance_count = 3

# ---- Availability Zones ----
opensearch_zone_awareness_enabled = false
opensearch_az_count               = 1

# ---- Networking ----
opensearch_vpc_subnet_ids     = ["subnet-008092de0af41925a"]
opensearch_security_group_ids = ["sg-0d8ff210281e0425c"]

# ---- EBS Storage ----
opensearch_ebs_enabled     = true
opensearch_ebs_volume_size = 100
opensearch_ebs_volume_type = "gp3"

# ---- Tags ----
opensearch_tags = {
  "name"       = "opensearch"
  "team"        = "sre"
  "owner"      = "plat"
  "environment" = "nonprod"
  "backup"      = "daily7"
}
