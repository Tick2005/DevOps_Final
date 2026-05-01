package com.startupx.common.product;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<ProductDocument, Long> {
	List<ProductDocument> findAllByOrderByIdAsc();
}