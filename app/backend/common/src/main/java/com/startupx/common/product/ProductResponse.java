package com.startupx.common.product;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ProductResponse {
  private Long id;
  private String name;
  private double price;
  private String color;
  private String category;
  private long stock;
  private String description;
  private String image;
  private LocalDateTime createdAt;
  private String source;
  private String host;
  private String tier;

  public static ProductResponse from(ProductEntity entity) {
    ProductResponse response = new ProductResponse();
    response.id = entity.getId();
    response.name = entity.getName();
    response.price = entity.getPrice();
    response.color = entity.getColor();
    response.category = entity.getCategory();
    response.stock = entity.getStock();
    response.description = entity.getDescription();
    response.image = entity.getImage();
    response.createdAt = entity.getCreatedAt();
    response.source = entity.getSource();
    return response;
  }

  public static ProductResponse from(ProductEntity entity, String host, String tier) {
    ProductResponse response = from(entity);
    response.host = host;
    response.tier = tier;
    return response;
  }

  public Long getId() {
    return id;
  }

  public String getName() {
    return name;
  }

  public double getPrice() {
    return price;
  }

  public String getColor() {
    return color;
  }

  public String getCategory() {
    return category;
  }

  public long getStock() {
    return stock;
  }

  public String getDescription() {
    return description;
  }

  public String getImage() {
    return image;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  public String getSource() {
    return source;
  }

  public String getHost() {
    return host;
  }

  public String getTier() {
    return tier;
  }
}
