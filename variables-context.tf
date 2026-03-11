variable "context" {
  type = object({
    account_id  = string
    project     = string
    region      = string
    environment = string
    name_prefix = string
    department  = string
    owner       = string
    domain      = string
    tags        = map(string)
  })
}
