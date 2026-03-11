variable "create" {
  type    = bool
  default = true
}

variable "context" {
  type = object({
    project     = string
    region      = string
    environment = string
    tags        = map(string)
  })
}
