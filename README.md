# OpenSearch on AWS — Managed vs EC2

Provision OpenSearch in two ways:
- **Managed with AWS OpenSearch Service** (`open-search-aws/`)
- **Self-managed on EC2** (`open-search-ec2/`)

```
├── modules
│   ├── opensearch
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── opensearch_ec2
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── open-search-aws
│   ├── main.tf
│   ├── providers.tf
│   ├── test.tfvars
│   └── variables.tf
└── open-search-ec2
    ├── main.tf
    ├── providers.tf
    ├── terraform.tfstate
    ├── test.tfvars
```

## Table of Contents

- [Prerequisites](#prerequisites)
- [Option 1: Managed OpenSearch Service](#option-1-managed-opensearch-service)
  - [Quick Start](#quick-start)
  - [Sample test.tfvars](#sample-testtfvars)
  - [Outputs](#outputs)
- [Option 2: OpenSearch on EC2](#option-2-opensearch-on-ec2)
  - [Quick Start](#quick-start-ec2)
  - [Sample test.tfvars](#sample-testtfvars-ec2)
  - [Reach the Cluster](#reach-the-cluster)
  - [Outputs](#outputs-ec2)
- [HA Notes](#ha-notes)
- [Common Gotchas](#common-gotchas)
- [Clean Up](#clean-up)
- [Choosing a Pattern](#choosing-a-pattern)

---

## Prerequisites

- Terraform >= 1.4
- AWS credentials with permission to create the relevant resources
- Existing VPC, subnet(s), key pair, and security group(s)
- (Optional) `AWS_PROFILE` / `AWS_REGION` set in your shell

---

## Option 1: Managed OpenSearch Service

### Quick Start

```sh
cd open-search-aws
terraform init -upgrade
terraform validate
terraform plan  -var-file="test.tfvars"
terraform apply -var-file="test.tfvars"
```

### Sample test.tfvars (managed)

```hcl
aws_region = "us-east-1"

opensearch_domain_name    = "opensearch-nonprod"
opensearch_version        = "OpenSearch_2.13"
opensearch_instance_type  = "m6g.large.search"
opensearch_instance_count = 3

# Single-AZ example. For HA, use 2–3 subnets across distinct AZs + enable zone awareness.
opensearch_zone_awareness_enabled = false
opensearch_az_count               = 1

opensearch_vpc_subnet_ids     = ["subnet-008092de0af41925a"]
opensearch_security_group_ids = ["sg-0d8ff210281e0425c"]

opensearch_ebs_enabled     = true
opensearch_ebs_volume_size = 100
opensearch_ebs_volume_type = "gp3"

opensearch_tags = {
  "application:name"       = "opensearch"
  "operations:team"        = "sre"
  "application:owner"      = "plat"
  "automation:environment" = "nonprod"
  "automation:backup"      = "daily7"
}

# Optional fine-grained access control:
# opensearch_master_user_name     = "admin"
# opensearch_master_user_password = "ChangeMe!"
```

### Outputs (managed)

- `terraform output opensearch_domain_arn`
- `terraform output opensearch_endpoint`
- `terraform output opensearch_dashboard_endpoint`

---

## Option 2: OpenSearch on EC2

Creates 3 EC2 nodes (configurable) with:
- `user_data` to install & configure OpenSearch
- EBS data volume mount
- Tag-based discovery via IAM (`ec2:DescribeInstances`)
- Ports: 9300 (transport) intra-SG; 9200 (HTTP) intra-SG by default

### Quick Start (EC2)

```sh
cd open-search-ec2
terraform init -upgrade
terraform validate
terraform plan  -var-file="test.tfvars"
terraform apply -var-file="test.tfvars"
```

### Sample test.tfvars (EC2)

```hcl
aws_region = "us-east-1"

# EC2 cluster
ec2_instance_count     = 3
ec2_instance_type      = "t3.xlarge"
ec2_ami_id             = "ami-020cba7c55df1f615"
ec2_subnet_ids         = ["subnet-008092de0af41925a"] # add 2–3 subnets across AZs for HA
ec2_key_name           = "TEST"
ec2_security_group_ids = ["sg-0d8ff210281e0425c"]
ec2_name_prefix        = "opensearch"

ec2_tags = {
  "application:name"       = "opensearch"
  "operations:team"        = "sre"
  "application:owner"      = "plat"
  "automation:environment" = "nonprod"
  "automation:backup"      = "daily7"
}

# EBS data volume
ec2_ebs_device_name           = "/dev/sdh"
ec2_ebs_volume_size           = 50
ec2_ebs_volume_type           = "gp3"
ec2_ebs_delete_on_termination = true
ec2_ebs_encrypted             = true

# OpenSearch runtime config
os_cluster_name    = "opensearch-nonprod"
os_version         = "2.13.0"
os_http_port       = 9200
os_transport_port  = 9300
os_heap            = "4g"
os_enable_security = false          # set true to enable security plugin
os_allow_cidr_http = []             # e.g., ["10.0.0.0/8"] to allow HTTP from private ranges
```

### Reach the Cluster

By default, HTTP (9200) is intra-SG only. Use an SSH tunnel or add your CIDR to `os_allow_cidr_http`.

```sh
ssh -i ~/.ssh/TEST.pem ec2-user@<node-public-ip> -L 9200:127.0.0.1:9200
curl http://127.0.0.1:9200
```

### Outputs (EC2)

- `terraform output instance_ids`
- `terraform output private_ips`
- `terraform output security_group_id`

---

## HA Notes

- **Managed:** set `opensearch_zone_awareness_enabled = true`, `opensearch_az_count = 2|3`, and provide 2–3 subnets in distinct AZs.
- **EC2:** provide 2–3 subnet IDs in distinct AZs to spread nodes; consider dedicated masters for larger clusters.

---

## Common Gotchas

- **Invalid single-line variable blocks:** use multi-line syntax:
  ```hcl
  variable "foo" {
    type    = string
    default = ""
  }
  ```
- **Duplicate providers:** each root should have one default provider `aws {}`.
- **Heredoc interpolation:** escape bash vars in Terraform templates as `$${VAR}`.
- **Security plugin (EC2):** if `os_enable_security = true`, configure users/roles + TLS; otherwise keep `false` for quick tests.

---

## Clean Up

From the chosen root:

```sh
terraform destroy -var-file="test.tfvars"
```

---

## Choosing a Pattern

- **Managed (OpenSearch Service):** minimal ops, built-in snapshots, easy scaling, IAM/FGAC options.
- **EC2:** full control (version, plugins, tuning), but you own patching, scaling, backups, and security hardening.

> **Tip:** add `terraform.tfstate*` to `.gitignore` and consider a remote backend (S3 + DynamoDB) for team