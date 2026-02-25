export interface CidrEntry {
  cidr: string;
  description: string;
  tags: string[];
}

export interface Proxy {
  url: string;
  ip: string;
  port: string;
  noproxy: string[];
}

export interface Network {
  public: CidrEntry[];
  internal: CidrEntry[];
  proxy: Proxy;
}

export interface Vault {
  ocid: string;
  crypto_endpoint: string;
  management_endpoint: string;
}

export interface Security {
  vault: Vault;
}

export interface GitHubRunner {
  labels: string[];
  image: string;
}

export interface GitHub {
  runner: GitHubRunner;
}

export interface Toolchain {
  github: GitHub;
}

export interface Observability {
  prometheus_scraping_cidr: string;
  loki_destination_cidr: string;
  loki_fqdn: string;
}

export interface Region {
  key: string;
  realm: string;
  network: Network;
  security: Security;
  toolchain: Toolchain;
  observability: Observability;
}

export interface RegionsMap {
  [regionKey: string]: Region;
}

export type RealmType = "public" | "government" | "sovereign" | "drcc" | "alloy" | "airgapped";

export interface Realm {
  type: RealmType;
  "geo-region": string;
  name: string;
  description: string;
  api_domain: string;
}

export interface RealmsMap {
  [realmKey: string]: Realm;
}
