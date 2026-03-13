# tfmodule-aws-ec2-dlm

EC2 Data Lifecycle Manager 정책을 구성하는 테라폼 모듈 입니다.


## Pre-Requisite

- `dlm.amazonaws.com` 서비스 `Role`을 사전에 활성화 해야 합니다. 만약, 아직 활성화되지 않았다면 아래 AWS CLI 명령으로 활성화 할 수 있습니다. 

```
aws iam create-service-linked-role --aws-service-name dlm.amazonaws.com
```

- `execution_role_arn`에 설정 할 DLM(Data Lifecycle Manager) 서비스 역할을 생성해야 합니다.
참고로, `git::https://github.com/oniops/tfmodule-aws-ec2-dlm.git//role?ref=v1.0.0` 모듈을 통해 쉽게 생성할 수 있습니다. 


## Usage

Data Lifecycle Manager 는 `policy_details` 정책 설정을 통해 snapshot 및 retention 규칙을 설정할 수 있습니다.

### Interval 기준 매일 스냅샷 백업 및 최근 7개 보관 정책

```hcl 
module "dlmRole" {
  source      = "git::https://github.com/oniops/tfmodule-aws-ec2-dlm.git//role?ref=v1.0.0"
  context = module.ctx.context
}

module "dlmRule101" {
  source      = "git::https://github.com/oniops/tfmodule-aws-ec2-dlm.git?ref=v1.0.0"
  context     = module.ctx.context
  name        = "daily-7days-retention"
  description = "Daily EBS snapshot policy with 7-day retention - Scheduled at 2400 KST"
  execution_role_arn = module.dlmRole.role_arn  # dlm.amazonaws.com 서비스가 사용하는 IAM Role 설정
  policy_details = {
    schedules = {
      create_rule = {
        interval      = 24
        interval_unit = "HOURS"
        times = ["15:00"] # KST 24:00
      }
      retain_rule = {
        count = 7
      }
      copy_tags = true
    }
    target_tags = {
      "ops:Snapshot" = "true"
    }
  }
}
```

### Cron 스케줄러 Daily 스냅샷 백업 및 14 일 보관 정책

매일 KST 기준 `24:01`에 스냅샷을 찍고, 2주(14일) 동안 스냅샷을 보관하는 백업 규칙

```hcl
module "dlmRule201" {
  source             = "git::https://github.com/oniops/tfmodule-aws-ec2-dlm.git?ref=v1.0.0"
  context            = module.ctx.context
  name               = "daily-14day-retention"
  description        = "Daily EBS snapshot policy executed at 1501 UTC with a 14-day age-based retention"
  execution_role_arn = module.dlmRole.role_arn
  policy_details = {
    resource_types = ["VOLUME"]
    schedules = {
      create_rule = {
        cron_expression = "cron(1 15 ? * * *)"
      }
      retain_rule = {
        interval      = 14
        interval_unit = "DAYS"
      }
    }
    target_tags = {
      "ops:Snapshot" = "true"
    }
  }
}
```

### Cron 스케줄러 Monthly 스냅샷 백업 및 30 일 보관 이후 아카이빙 1년 보관 유지 정책

매달 한 번 스냅샷을 찍어 초기 1달은 일반 저장소에, 이후 1년 동안은 저렴한 아카이브 저장소에 보관하는 장기 보존 하는 정책입니다.

* 주의) 스냅샷 아카이빙은 `90`일 분의 보관 비용이 한번에 청구되는점을 주의해야 합니다. 아카이빙은 데이터를 장기보관하는 용도에서 사용하고 실시간 또는 증분 백업 용도로 사용해선 안됩니다.

```hcl
module "dlmRule301" {
  source             = "git::https://github.com/oniops/tfmodule-aws-ec2-dlm.git?ref=v1.0.0"
  context            = module.ctx.context
  name               = "monthly-1year-archive"
  description        = "Monthly snapshot archiving policy - 30 days in Standard tier and then transitioned to Archive tier for 1 year"
  execution_role_arn = module.dlmRole.role_arn
  policy_details = {
    schedules = {
      create_rule = {
        cron_expression = "cron(0 18 1 * ? *)"
      }
      retain_rule = {
        interval      = 1
        interval_unit = "MONTHS"
      }
      archive_rule = {
        retention_archive_tier = {
          interval      = 1
          interval_unit = "YEARS"
        }
      }
    }
    target_tags = {
      "ops:Snapshot" = "monthly"
      "ops:Archive"  = "28"
    }
  }
}
```

### Cron 스케줄러 Daily AMI 이미지 백업 및 최신 7개 유지 정책

매일 24:01(KST)에 EC2 인스턴스를 대상으로 AMI 백업 이미지를 생성하고, 최신 7개만 유지하는 인스턴스 단위 백업 정책

* 주의) AMI 이미지 백업은 지원 종료로 `EoS`된 OS 임에도 즉시 인스턴스를 생성 할 수 있는 장점이 있지만, 반면 증분 백업을 지원하지 않으므로 과도한 스토리지 비용이 발생합니다.

```hcl
module "dlmRule401" {
  source             = "git::https://github.com/oniops/tfmodule-aws-ec2-dlm.git?ref=v1.0.0"
  context            = module.ctx.context
  name               = "daily-ami-backup-7count-retention"
  description        = "Daily instance-level AMI backup policy executed at 1501 UTC with a 7-count retention"
  execution_role_arn = module.dlmRole.role_arn
  policy_details = {
    resource_types = ["INSTANCE"]
    schedules = {
      create_rule = {
        cron_expression = "cron(1 15 ? * * *)"
      }
      retain_rule = {
        count = 7
      }
    }
    target_tags = {
      "ops:Snapshot"     = "true"
      "ops:SnapshotType" = "instance"
    }
  }
}
```

## Input Variables

<table>
<thead>
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Type</th>
        <th>Example</th>
        <th>Required</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td>create</td>
        <td>Whether to create a DLM policy.</td>
        <td>bool</td>
        <td>true</td>
        <td>no</td>
    </tr>
    <tr>
        <td>name</td>
        <td>A name for the DLM lifecycle policy</td>
        <td>string</td>
        <td>daily-7days-retention</td>
        <td>yes</td>
    </tr>
    <tr>
        <td>description</td>
        <td>A description for the DLM lifecycle policy.</td>
        <td>string</td>
        <td>Daily EBS snapshot policy with 7-day retention</td>
        <td>yes</td>
    </tr>
    <tr>
        <td>execution_role_arn</td>
        <td>The ARN of an IAM role that is able to be assumed by the DLM service.</td>
        <td>string</td>
        <td>arn:aws:iam::1111222233333:role/xxxDataLifecycleManagerDefaultRole</td>
        <td>yes</td>
    </tr>
    <tr>
        <td>policy_details</td>
        <td>API Gateway 에서 클라이언트용 Key 를 설정 합니다.</td>
        <td>object({})</td>
        <td>
<pre>
  policy_details = {
    schedules = {
      create_rule = {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["15:00"] # KST 24:00
      }
      retain_rule = {
        count = 1
      }
      copy_tags = true
    }
    target_tags = {
      "ops:Snapshot" = "true"
    }
  }
</pre></td>
        <td>yes</td>
    </tr>
</tbody>
</table>

## 주요 속성 주의 사항 및 기본 설정 값 참고

- `description`: DLM 서비스 설명 기입은 특수 문자가 포함 될 수 없습니다.
- `execution_role_arn`: `dlm.amazonaws.com` 서비스가 사용하는 IAM Role 을 설정합니다.
- `policy_details` : policy_details 속성은 아래 기본 값이 적용 됩니다.
    - `policy_details.resource_types` 속성이 없으면 `["VOLUME"]` 기본값이 설정 됩니다. (EBS 볼륨)
    - `policy_details.state` 속성이 없으면 `ENABLED` 기본값이 설정 됩니다.
    - `policy_details.tags_to_add` 속성이 없으면 `{ SnapshotCreator = "DLM" }` 기본값이 설정 됩니다.
    - `policy_details.copy_tags` 속성이 없으면 `true` 기본값이 설정 됩니다.
    - `policy_details.schedules.create_rule`: 스냅샷 생성 규칙을 설정합니다.
    - `policy_details.schedules.retain_rule`: 스냅샷 보관 규칙을 설정합니다.
    - `policy_details.schedules.archive_rule`: 스냅샷 아카이빙 장기 보관 규칙을 설정합니다.
    - `policy_details.schedules.target_tags`: 스냅샷 대상 EBS 볼륨을 식별하는 태그 규칙을 설정합니다. 


## 백업 대상 EBS 볼륨, EC2 인스턴스 태그 모범 사례

| Tag-Key               | Tag-Value   | Example                       | Description                        |
|-----------------------|-------------|-------------------------------|------------------------------------|
| ops:Snapshot          | daily       | daily, weekly, monthly, 1~999 | 스냅샷 생성 주기를 설정합니다. 숫자값은 day 기준 입니다. |
| ops:SnapshotType      | volume      | volume, instance              | 스냅샷 또는 AMI 백업 여부를 설정합니다.           |
| ops:SnapshotRetention | "30"        | 30, day-30, week-1, month-1   | 스냅샷 보관 기간을 설정합니다.                  |
| ops:Archive           | "true"      | true, false                   | 스냅샷 장기 보관 여부를 설정합니다.               |
| ops:ArchiveRetention  | "month-6"   | month-6, year-3               | 스냅샷 장기 보관 기간을 설정합니다. 6개월 또는 1년     |

- 태그키 및 태그값을 통해 EBS 볼륨 또는 EC2 인스턴스의 백업 및 보관 정책을 즉시 확인할 수 있으며, target_tags 키를 설정할 때도 용이 합니다. 