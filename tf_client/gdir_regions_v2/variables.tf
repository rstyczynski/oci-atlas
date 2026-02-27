variable "bucket_name" { type = string }
variable "object_name" { type = string }
variable "region_key"  { type = string, default = null }
variable "cidr_tag_filter" {
  type    = string
  default = "public"
}
