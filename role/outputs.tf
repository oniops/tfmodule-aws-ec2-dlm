output "role_arn" {
  value = var.create ? aws_iam_role.this[0].arn : ""
}

output "role_name" {
  value = var.create ? aws_iam_role.this[0].name : ""
}
