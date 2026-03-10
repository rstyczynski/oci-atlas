variable "bucket_name" {
  description = "Object Storage bucket name"
  type        = string
  default     = "gdir_info"
}

variable "object_name" {
  type    = string
  default = "regions/v2"
}

variable "region_key"  { 
  type = string
  nullable = true
  default = null
}

variable "cidr_tag_filter" {
  type    = string
  default = "public"
}
