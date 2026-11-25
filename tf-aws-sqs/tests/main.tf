module "sqs" {
  source = "../"

  name                      = var.name
  fifo_queue                = var.fifo_queue
  region                    = var.region
  resource_group_identifier = var.resource_group_identifier
  resource_tags             = var.resource_tags
}
