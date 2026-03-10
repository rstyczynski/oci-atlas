export interface gdir_config {
  /** Region key to use for single-region methods (e.g. "region11", "eu-region1"); optional when only getRegions/getRegionKeys are needed */
  regionKey?: string;
  /** Object Storage bucket name (default: gdir_info, override via GDIR_BUCKET) */
  bucketName?: string;
  /** Path to the OCI config file (default: "~/.oci/config") */
  ociConfigFile?: string;
  /** OCI config profile name (default: "DEFAULT") */
  ociProfile?: string;
}

export const DEFAULT_BUCKET = process.env.GDIR_BUCKET ?? "gdir_info";
