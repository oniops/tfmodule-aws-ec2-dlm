# You should create role by AWS CLI `aws dlm create-default-role --output text`
# see - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/service-role.html#default-service-roles
# terraform - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dlm_lifecycle_policy

locals {
  account_id  = var.context.account_id
  region      = var.context.region
  project     = var.context.project
  name_prefix = var.context.name_prefix
  dlm_name    = "${local.name_prefix}-${var.name}-dlm"
  tags        = var.context.tags
}

resource "aws_dlm_lifecycle_policy" "this" {
  count              = var.create ? 1 : 0
  description        = var.description
  execution_role_arn = var.execution_role_arn
  state              = var.policy_details.schedules.state

  policy_details {
    resource_types = var.policy_details.resource_types
    target_tags    = var.policy_details.target_tags

    schedule {
      name = local.dlm_name

      create_rule {
        # cron_expression이 있으면 우선 사용, 없으면 interval 관련 설정 적용
        cron_expression = var.policy_details.schedules.create_rule.cron_expression
        interval        = var.policy_details.schedules.create_rule.cron_expression == null ? var.policy_details.schedules.create_rule.interval : null
        interval_unit   = var.policy_details.schedules.create_rule.cron_expression == null ? var.policy_details.schedules.create_rule.interval_unit : null
        times           = var.policy_details.schedules.create_rule.cron_expression == null ? var.policy_details.schedules.create_rule.times : null
      }

      retain_rule {
        # count 방식인지 interval 방식인지에 따라 속성 값 적용
        count         = var.policy_details.schedules.retain_rule.count != null ? var.policy_details.schedules.retain_rule.count : null
        interval      = var.policy_details.schedules.retain_rule.count == null ? var.policy_details.schedules.retain_rule.interval : null
        interval_unit = var.policy_details.schedules.retain_rule.count == null ? var.policy_details.schedules.retain_rule.interval_unit : null
      }

      dynamic "archive_rule" {
        for_each = var.policy_details.schedules.archive_rule != null ? [var.policy_details.schedules.archive_rule] : []
        content {
          archive_retain_rule {
            retention_archive_tier {
              # count 방식인지 interval 방식인지에 따라 속성 값 적용d
              count         = archive_rule.value.retention_archive_tier.count != null ? archive_rule.value.retention_archive_tier.count : null
              interval      = archive_rule.value.retention_archive_tier.count == null ? archive_rule.value.retention_archive_tier.interval : null
              interval_unit = archive_rule.value.retention_archive_tier.count == null ? archive_rule.value.retention_archive_tier.interval_unit : null
            }
          }
        }
      }

      tags_to_add = var.policy_details.schedules.tags_to_add
      copy_tags   = var.policy_details.schedules.copy_tags
    }
  }

  tags = merge(local.tags, {
    Name = local.dlm_name
  })

}
