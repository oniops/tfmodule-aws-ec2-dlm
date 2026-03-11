locals {
  project = var.context.project
  tags = var.context.tags
  role_name = "${local.project}DataLifecycleManagerDefaultRole"
  role_trusted_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "Service" = "dlm.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })


  dlm_role_policies = var.create ? {
    AWSDataLifecycleManagerServiceRoleForAMIManagement = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRoleForAMIManagement"
    AWSDataLifecycleManagerServiceRole                 = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
  } : {}

}

resource "aws_iam_role" "this" {
  count              = var.create ? 1 : 0
  name               = local.role_name
  assume_role_policy = local.role_trusted_policy
  tags = merge(local.tags, {
    Name = local.role_name
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this[0].id
  for_each   = local.dlm_role_policies
  policy_arn = each.value
  depends_on = [aws_iam_role.this]
}
