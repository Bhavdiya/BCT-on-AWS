locals {
  tags = merge(var.additional_tags, {
    Created          = formatdate("YYYY-MM-DD", timestamp())
    AppRef           = var.resource_group_identifier
    Environment      = var.resource_tags["tag_env"]
    Location         = "aws ${lower(var.region)}"
    BusinessUnit     = var.resource_tags["tag_business_unit"]
    ApplicationName  = var.resource_tags["tag_app_name"]
    ApplicationOwner = var.resource_tags["tag_app_owner"]
  })
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  key_algorithm             = var.key_algorithm

  tags = local.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags["Created"]]
  }
}

resource "aws_route53_record" "validation" {
  for_each = var.hosted_zone_id == null ? {} : {
    for option in aws_acm_certificate.this.domain_validation_options :
    option.domain_name => option
  }

  zone_id         = var.hosted_zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  count = var.hosted_zone_id == null ? 0 : 1

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
