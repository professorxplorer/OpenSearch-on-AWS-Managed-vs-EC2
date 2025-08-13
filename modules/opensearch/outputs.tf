output "opensearch_domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.this.arn
}

output "opensearch_endpoint" {
  description = "OpenSearch HTTPS endpoint"
  value       = aws_opensearch_domain.this.endpoint
}

output "opensearch_dashboard_endpoint" {
  description = "Dashboards (Kibana) endpoint"
  value       = aws_opensearch_domain.this.dashboard_endpoint
}
