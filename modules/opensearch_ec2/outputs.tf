output "instance_ids" {
  value       = aws_instance.node[*].id
  description = "EC2 instance IDs"
}

output "private_ips" {
  value       = aws_instance.node[*].private_ip
  description = "EC2 private IPs"
}

output "security_group_id" {
  value       = aws_security_group.os.id
  description = "OpenSearch cluster SG ID"
}
