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
  private final RuntimeSourceResolver runtimeSourceResolver;

  @Value("${app.tier:common}")
  private String tier;

  public ProductService(ProductRepository repository, RuntimeSourceResolver runtimeSourceResolver) {
    this.repository = repository;
    this.runtimeSourceResolver = runtimeSourceResolver;
  }

  private String resolveRuntimeSource() {
    return runtimeSourceResolver.resolve();
  }

  public List<ProductResponse> listProducts(String host) {
    String source = resolveRuntimeSource();
    return repository.findAllByOrderByIdAsc().stream()
      .map((doc) -> ProductResponse.from(doc, host, tier, source))
      .collect(Collectors.toList());
  }

  public ProductResponse getProductById(Long id, String host) {
    String source = resolveRuntimeSource();
    ProductDocument product = repository.findById(id)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));
    return ProductResponse.from(product, host, tier, source);
  }

  public ProductResponse createProduct(ProductRequest request, String host) {
    String source = resolveRuntimeSource();
    ProductDocument product = mapRequest(new ProductDocument(), request);
    return ProductResponse.from(repository.save(product), host, tier, source);
  }

  public ProductResponse updateProduct(Long id, ProductRequest request, String host) {
    String source = resolveRuntimeSource();
    ProductDocument existing = repository.findById(id)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));

    ProductDocument updated = mapRequest(existing, request);
    return ProductResponse.from(repository.save(updated), host, tier, source);
  }

  public void deleteProduct(Long id) {
    if (!repository.existsById(id)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
    }
    repository.deleteById(id);
  }

  private ProductDocument mapRequest(ProductDocument target, ProductRequest request) {
    String source = resolveRuntimeSource();
    Long stock = request.getStock();

    target.setName(trim(request.getName()));
    target.setPrice(request.getPrice());
    target.setColor(trim(request.getColor()));
    target.setCategory(trim(request.getCategory()));
    target.setStock(stock == null ? 0L : stock);
    target.setDescription(trim(request.getDescription()));
    target.setImage(trim(request.getImage()));
    target.setSource(source);
    return target;
  }

  private String trim(String value) {
    return value == null ? "" : value.trim();
  }
}
