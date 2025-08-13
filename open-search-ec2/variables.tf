variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

# ---- EC2 base ----
variable "ec2_instance_count" {
  type        = number
  default     = 3
  description = "Number of EC2 instances (OpenSearch nodes)."
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.xlarge"
  description = "Instance type for OpenSearch nodes."
}

variable "ec2_ami_id" {
  type        = string
  default     = ""
  description = "AMI ID for the instances."
}

variable "ec2_subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet IDs to spread the nodes across."
}

variable "ec2_key_name" {
  type        = string
  default     = ""
  description = "EC2 key pair name."
}

variable "ec2_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Additional security group IDs to attach."
}

variable "ec2_name_prefix" {
  type        = string
  default     = "opensearch"
  description = "Name prefix for EC2 instances."
}

variable "ec2_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to EC2 instances."
}

# ---- EBS (data volume) ----
variable "ec2_ebs_device_name" {
  type        = string
  default     = "/dev/sdh"
  description = "Device name for the data volume."
}

variable "ec2_ebs_volume_size" {
  type        = number
  default     = 100
  description = "Data volume size in GiB."
}

variable "ec2_ebs_volume_type" {
  type        = string
  default     = "gp3"
  description = "Data volume type."
}

variable "ec2_ebs_delete_on_termination" {
  type        = bool
  default     = true
  description = "Whether to delete the data volume on termination."
}

variable "ec2_ebs_encrypted" {
  type        = bool
  default     = true
  description = "Whether the data volume is encrypted."
}

# ---- OpenSearch settings ----
variable "os_cluster_name" {
  type        = string
  default     = "os-ec2-cluster"
  description = "OpenSearch cluster name (also used for discovery tag)."
}

variable "os_version" {
  type        = string
  default     = "2.13.0"
  description = "OpenSearch version (bundle series)."
}

variable "os_http_port" {
  type        = number
  default     = 9200
  description = "HTTP API port."
}

variable "os_transport_port" {
  type        = number
  default     = 9300
  description = "Transport (cluster) port."
}

variable "os_heap" {
  type        = string
  default     = "2g"
  description = "JVM heap size (Xms = Xmx)."
}

variable "os_enable_security" {
  type        = bool
  default     = false
  description = "Enable the security plugin (set true to enable)."
}

variable "os_allow_cidr_http" {
  type        = list(string)
  default     = []
  description = "CIDR ranges allowed to access HTTP (9200). Leave empty to allow only intra-SG."
}
