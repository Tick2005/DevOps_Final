package com.startupx.common.product;

import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class RuntimeSourceResolver {
  private final String datasourceUrl;

  public RuntimeSourceResolver(@Value("${spring.datasource.url:}") String datasourceUrl) {
    this.datasourceUrl = datasourceUrl == null ? "" : datasourceUrl.trim();
  }

  public String resolve() {
    String value = datasourceUrl.toLowerCase(Locale.ROOT);

    if (value.startsWith("jdbc:postgresql:")) {
      return "PostgreSQL";
    }
    if (value.startsWith("jdbc:mysql:")) {
      return "MySQL";
    }
    if (value.startsWith("jdbc:mariadb:")) {
      return "MariaDB";
    }
    if (value.startsWith("jdbc:sqlserver:")) {
      return "SQL Server";
    }
    if (value.startsWith("jdbc:oracle:")) {
      return "Oracle";
    }
    if (value.startsWith("jdbc:h2:") || value.startsWith("jdbc:hsqldb:")) {
      return "InMemory";
    }
    if (value.isEmpty()) {
      return "Unknown";
    }

    return "JDBC";
  }
}