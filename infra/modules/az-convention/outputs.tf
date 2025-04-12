output "resource_name" {
  description = "The name of the resource"
  value       = local.resource_name
}

output "resource_name_without_delimiter" {
  description = "The name of the resource without delimiter"
  value       = local.resource_name_without_delimiter
}

output "project" {
  description = "The project name"
  value       = var.project
}
