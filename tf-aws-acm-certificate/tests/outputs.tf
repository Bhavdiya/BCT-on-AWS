output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = module.certificate.certificate_arn
}

output "domain_validation_options" {
  description = "DNS records to create when validation is not handled by Route 53"
  value       = module.certificate.domain_validation_options
}
