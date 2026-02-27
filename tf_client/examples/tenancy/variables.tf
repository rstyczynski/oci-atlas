variable "namespace" {
  type    = string
  default = "dummy_ns"
}

variable "bucket_name" {
  type    = string
  default = "dummy_bucket"
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
