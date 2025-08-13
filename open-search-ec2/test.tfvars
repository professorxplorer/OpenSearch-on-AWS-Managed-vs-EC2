aws_region = "us-east-1"

ec2_instance_count     = 3
ec2_instance_type      = "t3.xlarge"
ec2_ami_id             = "ami-020cba7c55df1f615"
ec2_subnet_ids         = ["subnet-008092de0af41925a"] # add 2 more subnets across AZs for HA
ec2_key_name           = "TEST"
ec2_security_group_ids = ["sg-0d8ff210281e0425c"]
ec2_name_prefix        = "opensearch"

ec2_tags = {
  "name"       = "opensearch"
  "team"        = "sre"
  "owner"      = "plat"
  "nvironment" = "nonprod"
  "backup"      = "daily7"
}

ec2_ebs_device_name           = "/dev/sdh"
ec2_ebs_volume_size           = 50
ec2_ebs_volume_type           = "gp3"
ec2_ebs_delete_on_termination = true
ec2_ebs_encrypted             = true

os_cluster_name = "opensearch-nonprod"
os_version      = "2.13.0"
os_heap         = "4g"

# Allow HTTP from nowhere by default (reach via SSH tunnel or add your CIDR here)
os_allow_cidr_http = []
