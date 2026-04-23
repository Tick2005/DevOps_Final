package com.startupx.common.product;

public class RuntimeInfoResponse {
  private final String status;
  private final String host;
  private final String source;
  private final String tier;
  private final String version;

  public RuntimeInfoResponse(String status, String host, String source, String tier, String version) {
    this.status = status;
    this.host = host;
    this.source = source;
    this.tier = tier;
    this.version = version;
  }

  public String getStatus() {
    return status;
  }

  public String getHost() {
    return host;
  }

  public String getSource() {
    return source;
  }

  public String getTier() {
    return tier;
  }

  public String getVersion() {
    return version;
  }
}
