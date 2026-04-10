package com.startupx.common.product;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/products")
@CrossOrigin(origins = "*")
public class ProductController {
  private final ProductService service;

  public ProductController(ProductService service) {
    this.service = service;
  }

  @GetMapping
  public List<ProductResponse> list(HttpServletRequest request) {
    return service.listProducts(resolveHost(request));
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public ProductResponse create(@Valid @RequestBody ProductRequest request, HttpServletRequest httpRequest) {
    return service.createProduct(request, resolveHost(httpRequest));
  }

  @PutMapping("/{id}")
  public ProductResponse update(@PathVariable Long id, @Valid @RequestBody ProductRequest request, HttpServletRequest httpRequest) {
    return service.updateProduct(id, request, resolveHost(httpRequest));
  }

  @DeleteMapping("/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void delete(@PathVariable Long id) {
    service.deleteProduct(id);
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
