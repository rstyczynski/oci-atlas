
variable "bucket_name" {
  description = "Object Storage bucket name (from core gdir_core module)"
  type        = string
  default     = "gdir_info"
}

variable "object_name" {
  description = "Object path for realms/v1 data"
  type        = string
  default     = "realms/v1"
}

variable "realm_key" {
  description = "Realm key for single-realm outputs (e.g. oc1, tst01). When null, single-realm locals are null."
  type        = string
  default     = null
  nullable    = true
}
