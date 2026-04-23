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

  public static ProductResponse from(ProductDocument document) {
    ProductResponse response = new ProductResponse();
    response.id = document.getId();
    response.name = document.getName();
    response.price = document.getPrice();
    response.color = document.getColor();
    response.category = document.getCategory();
    response.stock = document.getStock();
    response.description = document.getDescription();
    response.image = document.getImage();
    response.createdAt = document.getCreatedAt();
    response.source = document.getSource();
    return response;
  }

  public static ProductResponse from(ProductDocument document, String host, String tier) {
    ProductResponse response = from(document);
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