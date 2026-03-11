variable "create" {
  type    = bool
  default = true
}

variable "name" {
  type        = string
  description = "A name for the DLM lifecycle policy"
}

variable "description" {
  type        = string
  description = "A description for the DLM lifecycle policy. description should not contain special characters like `.` or `-`"
}

variable "execution_role_arn" {
  type        = string
  description = "The ARN of an IAM role that is able to be assumed by the DLM service."
}

variable "policy_details" {
  type = object({
    resource_types = optional(list(string), ["VOLUME"])
    schedules = object({
      state = optional(string, "ENABLED")
      create_rule = object({
        cron_expression = optional(string)
        interval        = optional(number)
        interval_unit   = optional(string)
        times           = optional(list(string))
      })
      retain_rule = optional(object({
        count         = optional(number)
        interval      = optional(number)
        interval_unit = optional(string) # DAYS, WEEKS, MONTHS, YEARS
      }), {})
      archive_rule = optional(object({
        retention_archive_tier = object({
          count         = optional(number)
          interval      = optional(number)
          interval_unit = optional(string) # DAYS, WEEKS, MONTHS, YEARS
        })
      }))
      tags_to_add = optional(map(string), { SnapshotCreator = "DLM" })
      copy_tags   = optional(bool, true)
    })
    target_tags = map(string)
  })
  description = <<-EOF
  policy_details = {
    resource_types         = ["VOLUME"]
    schedules              = {
      name                 = "daily"
      description          = "Run at 14H59 UTC everyday"
      state                = "ENABLED"
      create_rule          = {
        cron_expression    = "cron(59 14 ? * * *)"
      }
      retain_rule          = {
        count              = 15
      }
    }
    target_tags            = {
      "ops:Snapshot"          = true
      "ops:SnapshotRetention" = 15
    }
  }

  # by Crontab
      create_rule         = {
        cron_expression   = "cron(59 14 ? * * *)"
      }

  # by Interval
      create_rule {
        interval          = 24
        interval_unit     = "HOURS"
        times             = ["09:00"] # Started at (UTC)
      }

EOF
}

#
# variable "dlm_policies_old" {
#   type = map(object({
#     resource_types = list(string)
#
#   }))
#   default     = null
#   description = <<EOF
# Ex)
#   dlm_policies = {
#     resource_types = ["INSTANCE"]
#     "daily" = {
#       name                 = "daily-ami"
#       description          = "Run at 14H59 UTC everyday"
#       state                = "ENABLED"
#       cron_expression      = "cron(59 14 ? * * *)"
#       retain_rule_interval = 7
#       target_tags = {
#         "ops:Snapshot" = true
#       }
#     }
#   }
#
#
# [Cron Examples]
# 0 10 * * ? *            Run at 10:00 am (UTC+0) every day
# 15 12 * * ? *           Run at 12:15 pm (UTC+0) every day
# 0 18 ? * MON-FRI *      Run at 6:00 pm (UTC+0) every Monday through Friday
# 0 8 1 * ? *             Run at 8:00 am (UTC+0) every 1st day of the month
# 0/12 * * * ? *          Run every 15 minutes
# 0/10 * ? * MON-FRI *    Run every 10 minutes Monday through Friday
# 0/5 17 ? * MON-FRI *    Run every 5 minutes Monday through Friday between 8:00 am and 5:55 pm (UTC+0)
# 0/30 20-2 ? * MON-FRI * Run every 30 minutes Monday through Friday between 10:00 pm on the starting day to 2:00 am on the following day (UTC)
#                         Run from 12:00 am to 2:00 am on Monday morning (UTC).
# EOF
# }
#
