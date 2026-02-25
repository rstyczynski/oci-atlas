variable "region_key" {
  description = "Key to look up in regions.json (e.g. eu-zurich-1, region2). When unset, auto-detected from the active OCI connection via bucket OCID."
  type        = string
  default     = null
  nullable    = true
}

variable "cidr_tag_filter" {
  description = "Tag to filter CIDR entries with region_cidr_by_tag (e.g. OCI, OSN, vcn, mgmt)"
  type        = string
  default     = "OCI"
}
