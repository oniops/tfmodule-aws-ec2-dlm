output "id" {
  value = var.create ? aws_dlm_lifecycle_policy.this[0].id : ""
}

output "arn" {
  value = var.create ? aws_dlm_lifecycle_policy.this[0].arn : ""
}

output "state" {
  value = var.create ? aws_dlm_lifecycle_policy.this[0].state : ""
}

output "execution_role_arn" {
  value = var.create ? aws_dlm_lifecycle_policy.this[0].execution_role_arn : ""
}
