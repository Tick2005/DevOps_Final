package com.startupx.common.product;

import java.util.List;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ProductService {
  private final ProductRepository repository;

  @Value("${app.tier:common}")
  private String tier;

  public ProductService(ProductRepository repository) {
    this.repository = repository;
  }

  public List<ProductResponse> listProducts(String host) {
    return repository.findAll().stream()
      .map((entity) -> ProductResponse.from(entity, host, tier))
      .collect(Collectors.toList());
  }

  public ProductResponse createProduct(ProductRequest request, String host) {
    ProductEntity product = mapRequest(new ProductEntity(), request);
    return ProductResponse.from(repository.save(product), host, tier);
  }

  public ProductResponse updateProduct(Long id, ProductRequest request, String host) {
    ProductEntity existing = repository.findById(id)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));

    ProductEntity updated = mapRequest(existing, request);
    return ProductResponse.from(repository.save(updated), host, tier);
  }

  public void deleteProduct(Long id) {
    if (!repository.existsById(id)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
    }
    repository.deleteById(id);
  }

  private ProductEntity mapRequest(ProductEntity target, ProductRequest request) {
    target.setName(trim(request.getName()));
    target.setPrice(request.getPrice());
    target.setColor(trim(request.getColor()));
    target.setCategory(trim(request.getCategory()));
    target.setStock(request.getStock() == null ? 0L : request.getStock());
    target.setDescription(trim(request.getDescription()));
    target.setImage(trim(request.getImage()));
    target.setSource("PostgreSQL");
    return target;
  }

  private String trim(String value) {
    return value == null ? "" : value.trim();
  }
}
