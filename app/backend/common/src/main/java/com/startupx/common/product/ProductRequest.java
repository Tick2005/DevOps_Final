package com.startupx.common.product;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class ProductRequest {
  @NotBlank(message = "name is required")
  private String name;

  @NotNull(message = "price is required")
  @DecimalMin(value = "0.01", message = "price must be greater than 0")
  private Double price;

  @NotBlank(message = "color is required")
  private String color;

  private String category;

  @Min(value = 0, message = "stock cannot be negative")
  private Long stock;

  private String description;
  
  @Size(max = Integer.MAX_VALUE, message = "Image is too large")
  private String image;

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public Double getPrice() {
    return price;
  }

  public void setPrice(Double price) {
    this.price = price;
  }

  public String getColor() {
    return color;
  }

  public void setColor(String color) {
    this.color = color;
  }

  public String getCategory() {
    return category;
  }

  public void setCategory(String category) {
    this.category = category;
  }

  public Long getStock() {
    return stock;
  }

  public void setStock(Long stock) {
    this.stock = stock;
  }

  public String getDescription() {
    return description;
  }

  public void setDescription(String description) {
    this.description = description;
  }

  public String getImage() {
    return image;
  }

  public void setImage(String image) {
    this.image = image;
  }
}
