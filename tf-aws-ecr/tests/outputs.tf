output "repository_name" {
  description = "The name of the repository"
  value       = module.ecr.repository_name
}

output "repository_url" {
  description = "The URL to push images to"
  value       = module.ecr.repository_url
}
