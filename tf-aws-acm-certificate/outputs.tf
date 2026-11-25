output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = aws_acm_certificate.this.arn
}

output "domain_name" {
  description = "The domain name the certificate covers"
  value       = aws_acm_certificate.this.domain_name
}

output "domain_validation_options" {
  description = "DNS records to create when validation is not handled by Route 53"
  value       = aws_acm_certificate.this.domain_validation_options
}
