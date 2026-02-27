variable "bucket_name" {
  type    = string
  default = "gdir_info"
}

variable "object_name" { type = string }

variable "tenancy_key" {
  type    = string
  default = null
}

variable "region_key" {
  type    = string
  default = null
}

variable "cidr_tag_filter" {
  type    = string
  default = "vcn"
}
