locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    terraform   = "true"
  }
  az_names = slice(data.aws_availability_zones.available.names, 0, 2)
}
