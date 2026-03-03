variable "bucket_name" {
  type    = string
  default = "gdir_info"
}

variable "tenancies_object" {
  type    = string
  default = "tenancies/v1"
}

variable "tenancy_key" {
  type    = string
  default = null
}

variable "region_key" {
  type    = string
  default = null
}
