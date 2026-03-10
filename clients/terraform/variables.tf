variable "bucket_name" {
  description = "Object Storage bucket name"
  type        = string
  default     = "gdir_info"
}

variable "region_key" {
  description = "Region key for single-region outputs (e.g. eu-zurich-1). Defaults to null; set via TF_VAR_region_key or caller."
  type        = string
  default     = null
  nullable    = true
}
