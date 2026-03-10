variable "realm_key" {
  description = "Realm key to look up (e.g. oc1, oc19). When unset, auto-discovered from the active OCI region via regions/v1."
  type        = string
  default     = null
  nullable    = true
}
