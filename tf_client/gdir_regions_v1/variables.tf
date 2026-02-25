variable "namespace" {
  description = "OCI Object Storage namespace (from core gdir_core module)"
  type        = string
}

variable "bucket_name" {
  description = "Object Storage bucket name (from core gdir_core module)"
  type        = string
}

variable "object_name" {
  description = "Object path for regions/v1 data (override via GDIR_REGIONS_OBJECT equivalent)"
  type        = string
  default     = "regions/v1"
}

variable "region_key" {
  description = "Effective region key from the core gdir_core module (region_key output)"
  type        = string
}

variable "cidr_tag_filter" {
  description = "Tag to filter CIDR entries with region_cidr_by_tag (e.g. OCI, OSN, vcn, mgmt)"
  type        = string
  default     = "OCI"
}
