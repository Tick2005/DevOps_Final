# Migration từ MongoDB sang PostgreSQL

## Tổng quan

Hệ thống đã được chuyển đổi hoàn toàn từ MongoDB sang PostgreSQL để tận dụng AWS RDS managed service.

## Các thay đổi chính

### 1. Infrastructure (Terraform)

#### Trước (DocumentDB):
```hcl
resource "aws_docdb_cluster" "main" {
  engine = "docdb"
  instance_class = "db.t3.medium"
}
```

#### Sau (RDS PostgreSQL):
```hcl
resource "aws_db_instance" "main" {
  engine = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"  # Free tier eligible
  allocated_storage = 20
  max_allocated_storage = 100
}
```

**Lợi ích:**
- ✅ Free tier eligible (db.t3.micro)
- ✅ Auto-scaling storage (20GB → 100GB)
- ✅ Backup retention: 1 ngày
- ✅ CloudWatch logs integration

### 2. Backend Dependencies (pom.xml)

#### Đã xóa:
```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>
```

#### Đã thêm:
```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <scope>runtime</scope>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### 3. Application Configuration (application.yml)

#### Trước:
```yaml
spring:
  data:
    mongodb:
      uri: ${MONGODB_URI:mongodb://localhost:27017/startupx}
```

#### Sau:
```yaml
spring:
  datasource:
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/productdb}
    username: ${DATABASE_USERNAME:postgres}
    password: ${DATABASE_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect

management:
  endpoints:
    web:
      exposure:
        include: health,info
```

### 4. Entity Class

#### Trước (ProductDocument.java):
```java
@Document(collection = "products")
public class ProductDocument {
  @Id
  private String id;  // MongoDB ObjectId
  
  @CreatedDate
  private LocalDateTime createdAt;
  
  private String source = "MongoDB";
}
```

#### Sau (ProductEntity.java):
```java
@Entity
@Table(name = "products")
public class ProductEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;  // PostgreSQL auto-increment
  
  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;
  
  @Column(nullable = false)
  private String source = "PostgreSQL";
}
```

**Thay đổi chính:**
- `@Document` → `@Entity` + `@Table`
- `@Id` (MongoDB) → `@Id` + `@GeneratedValue` (JPA)
- ID type: `String` → `Long`
- `@CreatedDate` → `@CreationTimestamp`
- Thêm `@Column` constraints

### 5. Repository Interface

#### Trước:
```java
public interface ProductRepository extends MongoRepository<ProductDocument, String> {
}
```

#### Sau:
```java
public interface ProductRepository extends JpaRepository<ProductEntity, Long> {
}
```

### 6. Service Layer

#### Thay đổi:
- `ProductDocument` → `ProductEntity`
- ID type: `String` → `Long`
- `source = "MongoDB"` → `source = "PostgreSQL"`

### 7. Controller

#### Thay đổi:
```java
// Trước
@PathVariable String id

// Sau
@PathVariable Long id
```

### 8. Response DTO

#### Thay đổi:
```java
// Trước
private String id;
public static ProductResponse from(ProductDocument document)

// Sau
private Long id;
public static ProductResponse from(ProductEntity entity)
```

### 9. Kubernetes Secrets

#### Trước (k8s/secret.yaml):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
stringData:
  MONGODB_URI: "mongodb://admin:password@docdb-endpoint:27017/..."
```

#### Sau:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
stringData:
  DATABASE_URL: "jdbc:postgresql://rds-endpoint:5432/productdb"
  DATABASE_USERNAME: "postgres"
  DATABASE_PASSWORD: "YourSecurePassword123!"
```

### 10. Kubernetes Deployment

#### Environment Variables:
```yaml
# Trước
- name: MONGODB_URI
  valueFrom:
    secretKeyRef:
      name: mongodb-secret
      key: MONGODB_URI

# Sau
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: database-secret
      key: DATABASE_URL
- name: DATABASE_USERNAME
  valueFrom:
    secretKeyRef:
      name: database-secret
      key: DATABASE_USERNAME
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: database-secret
      key: DATABASE_PASSWORD
```

### 11. Docker Compose (Local Development)

#### Trước:
```yaml
services:
  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
```

#### Sau:
```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: productdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

## Checklist Migration

### Terraform
- [x] Đổi documentdb.tf → rds.tf
- [x] Cập nhật variables.tf
- [x] Cập nhật outputs.tf
- [x] Cập nhật terraform.tfvars.example

### Backend Code
- [x] Cập nhật pom.xml dependencies
- [x] Cập nhật application.yml
- [x] ProductDocument → ProductEntity
- [x] Cập nhật ProductRepository
- [x] Cập nhật ProductService
- [x] Cập nhật ProductController
- [x] Cập nhật ProductResponse
- [x] Cập nhật DataInitializerService

### Kubernetes
- [x] Cập nhật secret.yaml
- [x] Cập nhật backend-deployment.yaml

### Docker Compose
- [x] Cập nhật docker-compose.yml

### Build & Test
- [x] Maven compile thành công
- [x] Maven package thành công
- [x] Không có errors (chỉ warnings về null safety)

## Testing

### Local Testing
```bash
# Start PostgreSQL
docker compose up -d postgres

# Build backend
cd app/backend/common
mvn clean package -DskipTests

# Run backend
java -jar target/common-1.0.0.jar

# Test API
curl http://localhost:8080/api/products
```

### Full Stack Testing
```bash
# Start all services
docker compose up -d --build

# Access
# Frontend: http://localhost:5173
# Backend: http://localhost:8080/api/products
```

## Deployment Steps

### 1. Update Terraform Variables
```bash
cd terraform
nano terraform.tfvars
# Đổi documentdb_* → rds_*
```

### 2. Apply Infrastructure
```bash
terraform init
terraform apply
```

### 3. Get RDS Endpoint
```bash
terraform output rds_endpoint
# Output: devops-final-postgres.xxxxx.ap-southeast-1.rds.amazonaws.com:5432
```

### 4. Update Kubernetes Secret
```bash
cd ../k8s
nano secret.yaml
# Thay rds-endpoint bằng giá trị thực từ terraform output
```

### 5. Deploy to EKS
```bash
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml
```

### 6. Verify Deployment
```bash
kubectl get pods -n devops-final
kubectl logs -f deployment/backend -n devops-final
```

## Rollback Plan

Nếu cần rollback về MongoDB:

1. Revert Terraform changes
2. Revert backend code changes
3. Revert Kubernetes manifests
4. Redeploy

Hoặc sử dụng Git:
```bash
git revert <commit-hash>
```

## Performance Comparison

| Metric | MongoDB (DocumentDB) | PostgreSQL (RDS) |
|--------|---------------------|------------------|
| Instance Cost | db.t3.medium (~$70/mo) | db.t3.micro (Free tier) |
| Storage | Fixed | Auto-scaling (20-100GB) |
| Backup | 1 day | 1 day |
| Maintenance | Manual | Automated |
| Monitoring | Basic | CloudWatch integrated |

## Notes

- PostgreSQL sử dụng auto-increment ID (Long) thay vì ObjectId (String)
- JPA Hibernate tự động tạo schema với `ddl-auto: update`
- Health check endpoint: `/actuator/health`
- Database connection pool được quản lý bởi HikariCP (default)
- Transactions được hỗ trợ tốt hơn với PostgreSQL

## Troubleshooting

### Backend không kết nối được database
```bash
# Check RDS endpoint
terraform output rds_endpoint

# Check secret
kubectl get secret database-secret -n devops-final -o yaml

# Check logs
kubectl logs -f deployment/backend -n devops-final
```

### Schema không tạo tự động
```yaml
# Trong application.yml, đảm bảo:
spring:
  jpa:
    hibernate:
      ddl-auto: update  # hoặc create-drop cho dev
```

### Connection timeout
```yaml
# Kiểm tra security group cho phép traffic từ EKS nodes
# Port: 5432
# Source: VPC CIDR (10.0.0.0/16)
```
