import * as objectstorage from "oci-objectstorage";
import * as common from "oci-common";
import { Readable } from "stream";
import { gdir_config, DEFAULT_BUCKET } from "./config";

export async function streamToString(stream: Readable): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks).toString("utf-8");
}

/**
 * Core client (gdir) — handles OCI authentication, region auto-discovery via bucket OCID,
 * and raw object fetch. Schema-independent.
 */
export class gdir {
  private _client: objectstorage.ObjectStorageClient | null = null;
  private readonly ociConfig: gdir_config;
  protected readonly bucketName: string;
  protected readonly objectName: string;

  private readonly explicitRegionKey?: string;
  private cachedRegionKey: string | null = null;
  private cachedNamespace: string | null = null;

  constructor(config: gdir_config = {}, objectName: string) {
    this.ociConfig = config;
    this.bucketName = config.bucketName ?? DEFAULT_BUCKET;
    this.objectName = objectName;
    this.explicitRegionKey = config.regionKey;
  }

  /** OCI client — lazily initialised on first use so subclasses that override
   *  fetchObject() (e.g. test mocks) never need ~/.oci/config. */
  protected get client(): objectstorage.ObjectStorageClient {
    if (!this._client) {
      const provider = new common.ConfigFileAuthenticationDetailsProvider(
        this.ociConfig.ociConfigFile,
        this.ociConfig.ociProfile
      );
      this._client = new objectstorage.ObjectStorageClient({ authenticationDetailsProvider: provider });
    }
    return this._client;
  }

  /** Namespace — cached after first call */
  protected async getNamespace(): Promise<string> {
    if (this.cachedNamespace) return this.cachedNamespace;
    const res = await this.client.getNamespace({});
    this.cachedNamespace = res.value;
    return this.cachedNamespace;
  }

  /**
   * Region key — explicit config wins; otherwise extracted from bucket OCID.
   * OCID format: ocid1.bucket.<realm>.<region>.<hash> → split(".")[3]
   * Mirrors TF (bucket_id split) and CLI (endpoint URL grep).
   */
  protected async resolveRegionKey(): Promise<string> {
    if (this.explicitRegionKey) return this.explicitRegionKey;
    if (this.cachedRegionKey) return this.cachedRegionKey;

    const namespace = await this.getNamespace();
    const res = await this.client.getBucket({ namespaceName: namespace, bucketName: this.bucketName });
    const bucketId = res.bucket.id;
    if (!bucketId) throw new Error("Could not read bucket OCID to discover active region");

    this.cachedRegionKey = bucketId.split(".")[3];
    return this.cachedRegionKey;
  }

  /** Fetch raw object content from the bucket as a string */
  protected async fetchObject(): Promise<string> {
    const namespace = await this.getNamespace();
    const res = await this.client.getObject({
      namespaceName: namespace,
      bucketName: this.bucketName,
      objectName: this.objectName,
    });
    return streamToString(res.value as Readable);
  }
}
