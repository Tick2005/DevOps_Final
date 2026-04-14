package com.startupx.common.product;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/health")
@CrossOrigin(origins = "*")
public class RuntimeController {
  private final RuntimeSourceResolver runtimeSourceResolver;

  @Value("${app.tier:common}")
  private String tier;

  @Value("${app.exam-tier:}")
  private String examTier;

  @Value("${app.version:v1.0.0}")
  private String version;

  public RuntimeController(RuntimeSourceResolver runtimeSourceResolver) {
    this.runtimeSourceResolver = runtimeSourceResolver;
  }

  @GetMapping("/runtime")
  public RuntimeInfoResponse runtime(HttpServletRequest request) {
    return new RuntimeInfoResponse(
      "Online",
      resolveHost(request),
      runtimeSourceResolver.resolve(),
      resolveExamTierLabel(),
      version
    );
  }

  private String resolveExamTierLabel() {
    String explicit = normalize(examTier);
    if (!explicit.isEmpty()) {
      return mapTierNumberToLabel(explicit);
    }

    String normalizedTier = normalize(tier);
    if (normalizedTier.contains("kubernetes") || normalizedTier.contains("k8s") || normalizedTier.contains("eks") || normalizedTier.contains("gke") || normalizedTier.contains("aks")) {
      return mapTierNumberToLabel("5");
    }
    if (normalizedTier.contains("swarm")) {
      return mapTierNumberToLabel("4");
    }
    if (normalizedTier.contains("multi-server") || normalizedTier.contains("multiserver") || normalizedTier.contains("load-balancer") || normalizedTier.contains("alb") || normalizedTier.contains("nginx-lb") || normalizedTier.contains("haproxy")) {
      return mapTierNumberToLabel("3");
    }
    if (normalizedTier.contains("docker-compose") || normalizedTier.contains("containerized") || normalizedTier.contains("single-server-container")) {
      return mapTierNumberToLabel("2");
    }
    if (normalizedTier.contains("pm2") || normalizedTier.contains("systemd") || normalizedTier.contains("non-container") || normalizedTier.contains("noncontainer")) {
      return mapTierNumberToLabel("1");
    }

    return "Unclassified";
  }

  private String mapTierNumberToLabel(String value) {
    return switch (value) {
      case "1" -> "Tier 1 - Single-Server, Non-Containerized";
      case "2" -> "Tier 2 - Single-Server, Containerized (Docker Compose)";
      case "3" -> "Tier 3 - Multi-Server with Centralized Load Balancing";
      case "4" -> "Tier 4 - Docker Swarm Orchestration";
      case "5" -> "Tier 5 - Kubernetes-Based Architecture";
      default -> "Unclassified";
    };
  }

  private String normalize(String value) {
    return value == null ? "" : value.trim().toLowerCase();
  }

  private String resolveHost(HttpServletRequest request) {
    String forwardedHost = request.getHeader("X-Forwarded-Host");
    if (forwardedHost != null && !forwardedHost.isBlank()) {
      return forwardedHost.split(",")[0].trim();
    }

    String host = request.getHeader("Host");
    if (host != null && !host.isBlank()) {
      return host.trim();
    }

    String serverName = request.getServerName();
    int port = request.getServerPort();
    if (port == 80 || port == 443) {
      return serverName;
    }
    return serverName + ":" + port;
  }
}
