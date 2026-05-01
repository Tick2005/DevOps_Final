package com.startupx.common.product;

import java.util.Arrays;
import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;

@Service
public class DataInitializerService implements CommandLineRunner {
  private final ProductRepository repository;
  private final RuntimeSourceResolver runtimeSourceResolver;

  public DataInitializerService(ProductRepository repository, RuntimeSourceResolver runtimeSourceResolver) {
    this.repository = repository;
    this.runtimeSourceResolver = runtimeSourceResolver;
  }

  @Override
  public void run(String... args) throws Exception {
    String runtimeSource = runtimeSourceResolver.resolve();

    // Only seed if database is empty
    if (repository.count() > 0) {
      return;
    }

    List<ProductDocument> seedData = Arrays.asList(
      createProduct("Laptop Pro", 1299.99, "Silver", "Electronics", 15, "High-performance laptop", "", runtimeSource),
      createProduct("Wireless Mouse", 49.99, "Black", "Accessories", 120, "Ergonomic design", "", runtimeSource),
      createProduct("USB-C Cable", 19.99, "Black", "Cables", 200, "Fast charging cable", "", runtimeSource),
      createProduct("Monitor 4K", 599.99, "Black", "Electronics", 25, "Ultra HD display", "", runtimeSource),
      createProduct("Keyboard Mechanical", 149.99, "RGB", "Accessories", 80, "RGB backlit", "", runtimeSource),
      createProduct("Webcam HD", 79.99, "Black", "Electronics", 60, "1080p resolution", "", runtimeSource),
      createProduct("Desk Lamp", 89.99, "White", "Furniture", 45, "LED with USB charger", "", runtimeSource),
      createProduct("Phone Stand", 24.99, "Silver", "Accessories", 150, "Adjustable angle", "", runtimeSource),
      createProduct("Portable SSD", 199.99, "Black", "Storage", 35, "1TB solid state", "", runtimeSource),
      createProduct("HDMI Cable", 14.99, "Black", "Cables", 300, "High speed cable", "", runtimeSource),
      createProduct("Headphones", 199.99, "Black", "Audio", 50, "Noise cancelling", "", runtimeSource),
      createProduct("USB Hub", 39.99, "Black", "Accessories", 90, "7-port hub", "", runtimeSource),
      createProduct("Phone Case", 29.99, "Blue", "Accessories", 200, "Protective case", "", runtimeSource),
      createProduct("Screen Protector", 9.99, "Clear", "Accessories", 500, "Tempered glass", "", runtimeSource),
      createProduct("Power Bank", 59.99, "Black", "Electronics", 100, "20000mAh capacity", "", runtimeSource),
      createProduct("Charging Dock", 44.99, "White", "Accessories", 75, "Multi-device", "", runtimeSource)
    );

    repository.saveAll(seedData);
  }

  private ProductDocument createProduct(String name, double price, String color, String category, long stock, String description, String image, String source) {
    ProductDocument doc = new ProductDocument();
    doc.setName(name);
    doc.setPrice(price);
    doc.setColor(color);
    doc.setCategory(category);
    doc.setStock(stock);
    doc.setDescription(description);
    doc.setImage(image);
    doc.setSource(source);
    return doc;
  }
}