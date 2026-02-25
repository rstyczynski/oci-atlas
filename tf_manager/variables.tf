variable "compartment_id" {
  description = "OCID of the compartment where the bucket will be created. When null, the tenancy root compartment is auto-discovered from ~/.oci/config."
  type        = string
  default     = null
  nullable    = true
}

variable "bucket_name" {
  description = "Object Storage bucket name"
  type        = string
  default     = "gdir_info"
}


variable "enable_retention" {
  description = "Enable retention rule on the bucket (read-only until time_rule_locked)"
  type        = bool
  default     = false
}

variable "retention_time_amount" {
  description = "Retention rule duration amount"
  type        = number
  default     = 1
}

variable "retention_time_unit" {
  description = "Retention rule duration unit (e.g. YEARS)"
  type        = string
  default     = "YEARS"
}

variable "retention_rule_locked" {
  description = "Retention rule lock date (RFC 3339); objects are read-only until this time"
  type        = string
  default     = "2099-01-01T00:00:00Z"
}

