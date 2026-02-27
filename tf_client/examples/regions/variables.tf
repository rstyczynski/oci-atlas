variable "bucket_name" {
  type    = string
  default = "gdir_info"
}

variable "regions_object" {
  type    = string
  default = "regions/v2"
}

variable "tenancies_object" {
  type    = string
  default = "tenancies/v1"
}

variable "tenancy_key" {
  type    = string
  default = "acme_prod"
}

variable "region_key" {
  type    = string
  default = "eu-zurich-1"
}

variable "cidr_tag_filter" {
  type    = string
  default = "public"
}
