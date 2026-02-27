variable "namespace"    { type = string }
variable "bucket_name"  { type = string }
variable "object_name"  { type = string }
variable "tenancy_key"  { type = string }
variable "region_key"   { type = string }
variable "cidr_tag_filter" { type = string default = "vcn" }
