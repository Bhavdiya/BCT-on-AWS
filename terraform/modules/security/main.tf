# CloudFront publishes the set of IP ranges its origin-facing servers use as a
# managed prefix list. Referencing it keeps the ALB unreachable from anywhere
# except the CDN, so the WAF at the edge cannot be bypassed.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  count = var.restrict_alb_to_cloudfront ? 1 : 0

  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb"
  description = "Public ingress to the application load balancer"
  vpc_id      = var.vpc_id

}

resource "aws_security_group" "ecs" {
  name        = "${var.name_prefix}-ecs"
  description = "API tasks. Reachable only from the load balancer"
  vpc_id      = var.vpc_id

}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds"
  description = "Database. Reachable only from the API tasks"
  vpc_id      = var.vpc_id

}

# Rules are separate resources rather than inline blocks so the ALB and ECS
# groups can reference each other without a dependency cycle.

resource "aws_vpc_security_group_ingress_rule" "alb_https_cloudfront" {
  count = var.restrict_alb_to_cloudfront ? 1 : 0

  security_group_id = aws_security_group.alb.id
  description       = "Listener traffic from CloudFront origin-facing ranges"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront[0].id
  from_port         = var.alb_listener_port
  to_port           = var.alb_listener_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_extra" {
  for_each = toset(var.alb_extra_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "Listener traffic from an explicitly allowed range"
  cidr_ipv4         = each.value
  from_port         = var.alb_listener_port
  to_port           = var.alb_listener_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to the API tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Application traffic from the load balancer"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

# Tasks need outbound HTTPS for the LLM provider and the Entra OIDC metadata
# document, neither of which has a PrivateLink endpoint.
resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id
  description       = "HTTPS to AWS endpoints, the identity provider and the LLM provider"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Database connections"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

# The only ingress the database accepts. No CIDR rule exists on this group at
# all, so there is no path by which 0.0.0.0/0 could reach the listener.
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "SQL Server from the API tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "redis" {
  count = var.enable_redis ? 1 : 0

  name        = "${var.name_prefix}-redis"
  description = "Cache. Reachable only from the API tasks"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  count = var.enable_redis ? 1 : 0

  security_group_id            = aws_security_group.redis[0].id
  description                  = "Redis from the API tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_redis" {
  count = var.enable_redis ? 1 : 0

  security_group_id            = aws_security_group.ecs.id
  description                  = "Cache connections"
  referenced_security_group_id = aws_security_group.redis[0].id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "opensearch" {
  count = var.enable_search ? 1 : 0

  name        = "${var.name_prefix}-search"
  description = "Search domain. Reachable only from the API tasks"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "search_from_ecs" {
  count = var.enable_search ? 1 : 0

  security_group_id            = aws_security_group.opensearch[0].id
  description                  = "HTTPS from the API tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
