terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
}

provider "oci" {
  # Configuration via environment variables:
  # OCI_CLI_USER, OCI_CLI_FINGERPRINT, OCI_CLI_KEY_FILE, OCI_CLI_TENANCY, OCI_CLI_REGION
  # or use ~/.oci/config: tenancy_ocid, user_ocid, fingerprint, private_key_path, region
}
