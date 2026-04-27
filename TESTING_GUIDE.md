# Application Testing Guide

## Overview

This guide provides comprehensive testing commands and procedures for the ProductX application at all levels: local development, Docker, Kubernetes, and production.

---

## Table of Contents

1. [Local Development Testing](#local-development-testing)
2. [Docker Testing](#docker-testing)
3. [Kubernetes Testing](#kubernetes-testing)
4. [Production Testing](#production-testing)
5. [Load Testing](#load-testing)
6. [Security Testing](#security-testing)

---

## Local Development Testing

### Prerequisites
```bash
# Backend requirements
- Java 17+
- Maven 3.8+
- PostgreSQL 14+

# Frontend requirements
- Node.js 18+
- npm 9+
```

### Backend Testing

#### 1. Setup Local Database
```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Create database and user
sudo -u postgres psql
CREATE DATABASE productx_db;
CREATE USER productx_user WITH PASSWORD 'SecurePassword123!';
GRANT ALL PRIVILEGES ON DATABASE productx_db TO productx_user;
\q
```

#### 2. Configure Environment
```bash
cd app/backend/common

# Set environment variables
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/productx_db
export SPRING_DATASOURCE_USERNAME=productx_user
export SPRING_DATASOURCE_PASSWORD=SecurePassword123!
export APP_TIER=local
export PORT=8080
```

#### 3. Build and Run
```bash
# Build
mvn clean package -DskipTests

# Run
mvn spring-boot:run

# Or run JAR directly
java -jar target/common-0.0.1-SNAPSHOT.jar
```

#### 4. Test Backend API
```bash
# Health check
curl http://localhost:8080/actuator/health

# List products
curl http://localhost:8080/api/products

# Get single product
curl http://localhost:8080/api/products/1

# Create product
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 99.99,
    "color": "Blue",
    "category": "Test",
    "stock": 10,
    "description": "Test description",
    "image": "https://via.placeholder.com/150"
  }'

# Update product
curl -X PUT http://localhost:8080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Product",
    "price": 149.99,
    "color": "Red",
    "category": "Test",
    "stock": 20,
    "description": "Updated description",
    "image": "https://via.placeholder.com/150"
  }'

# Delete product
curl -X DELETE http://localhost:8080/api/products/1
```

### Frontend Testing

#### 1. Configure Environment
```bash
cd app/frontend

# Create .env file
cat > .env << EOF
VITE_API_BASE=/api
VITE_PROXY_TARGET=http://localhost:8080
EOF
```

#### 2. Install Dependencies
```bash
npm install
```

#### 3. Run Development Server
```bash
npm run dev
```

#### 4. Test Frontend
```bash
# Open browser
open http://localhost:5173

# Or use curl
curl http://localhost:5173
```

#### 5. Build for Production
```bash
npm run build

# Preview production build
npm run preview
```

---

## Docker Testing

### Build Images

#### Backend
```bash
cd app/backend/common

# Build image
docker build -t productx-backend:test .

# Verify image
docker images | grep productx-backend
```

#### Frontend
```bash
cd app/frontend

# Build image
docker build -t productx-frontend:test .

# Verify image
docker images | grep productx-frontend
```

### Test with Docker Compose

#### 1. Start Services
```bash
cd DevOps_Final

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

#### 2. View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres
```

#### 3. Test Application
```bash
# Backend health
curl http://localhost:8080/actuator/health

# Frontend
curl http://localhost:80

# API through frontend proxy
curl http://localhost:80/api/products
```

#### 4. Test Database Connection
```bash
# Connect to PostgreSQL container
docker-compose exec postgres psql -U productx_user -d productx_db

# List tables
\dt

# Query products
SELECT * FROM products LIMIT 5;

# Exit
\q
```

#### 5. Stop Services
```bash
docker-compose down

# Remove volumes (clean slate)
docker-compose down -v
```

### Security Scanning

#### Scan Images with Trivy
```bash
# Install Trivy
sudo apt-get install trivy

# Scan backend image
trivy image productx-backend:test

# Scan frontend image
trivy image productx-frontend:test

# Scan with severity filter
trivy image --severity HIGH,CRITICAL productx-backend:test

# Generate report
trivy image --format json --output backend-scan.json productx-backend:test
```

---

## Kubernetes Testing

### Prerequisites
```bash
# Configure kubectl
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Deployment Testing

#### 1. Check Namespace
```bash
# List namespaces
kubectl get namespaces

# Check productx namespace
kubectl get all -n productx
```

#### 2. Check Deployments
```bash
# List deployments
kubectl get deployments -n productx

# Describe deployment
kubectl describe deployment backend -n productx
kubectl describe deployment frontend -n productx

# Check deployment status
kubectl rollout status deployment/backend -n productx
kubectl rollout status deployment/frontend -n productx
```

#### 3. Check Pods
```bash
# List pods
kubectl get pods -n productx

# Describe pod
kubectl describe pod <pod-name> -n productx

# Check pod logs
kubectl logs -l app=backend -n productx --tail=100
kubectl logs -l app=frontend -n productx --tail=100

# Follow logs
kubectl logs -l app=backend -n productx -f

# Check previous pod logs (if crashed)
kubectl logs <pod-name> -n productx --previous
```

#### 4. Check Services
```bash
# List services
kubectl get svc -n productx

# Describe service
kubectl describe svc backend-svc -n productx
kubectl describe svc frontend-svc -n productx

# Check endpoints
kubectl get endpoints -n productx
```

#### 5. Check Ingress
```bash
# List ingress
kubectl get ingress -n productx

# Describe ingress
kubectl describe ingress app-ingress -n productx

# Get ALB address
kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

#### 6. Check HPA (Horizontal Pod Autoscaler)
```bash
# List HPA
kubectl get hpa -n productx

# Describe HPA
kubectl describe hpa backend-hpa -n productx
kubectl describe hpa frontend-hpa -n productx

# Watch HPA in real-time
kubectl get hpa -n productx --watch
```

### Pod Testing

#### 1. Execute Commands in Pod
```bash
# Get shell access
kubectl exec -it <backend-pod-name> -n productx -- /bin/bash

# Check Java version
kubectl exec <backend-pod-name> -n productx -- java -version

# Check environment variables
kubectl exec <backend-pod-name> -n productx -- env | grep SPRING

# Test database connection from pod
kubectl exec <backend-pod-name> -n productx -- curl http://localhost:8080/actuator/health
```

#### 2. Port Forwarding
```bash
# Forward backend port
kubectl port-forward -n productx svc/backend-svc 8080:8080

# Forward frontend port
kubectl port-forward -n productx svc/frontend-svc 8081:80

# Test locally
curl http://localhost:8080/api/products
curl http://localhost:8081
```

#### 3. Copy Files from Pod
```bash
# Copy logs
kubectl cp productx/<pod-name>:/app/logs/application.log ./application.log

# Copy config
kubectl cp productx/<pod-name>:/app/config/application.yml ./application.yml
```

### ConfigMap and Secrets Testing

#### 1. Check ConfigMap
```bash
# List ConfigMaps
kubectl get configmap -n productx

# View ConfigMap
kubectl describe configmap app-config -n productx

# Get ConfigMap YAML
kubectl get configmap app-config -n productx -o yaml
```

#### 2. Check Secrets
```bash
# List secrets
kubectl get secrets -n productx

# Describe secret (values are hidden)
kubectl describe secret app-secrets -n productx

# Decode secret value
kubectl get secret app-secrets -n productx -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

### Resource Usage Testing

#### 1. Check Resource Consumption
```bash
# Pod resource usage
kubectl top pods -n productx

# Node resource usage
kubectl top nodes

# Detailed pod metrics
kubectl describe pod <pod-name> -n productx | grep -A 5 "Limits\|Requests"
```

#### 2. Check Events
```bash
# Recent events in namespace
kubectl get events -n productx --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n productx --watch

# Filter events by type
kubectl get events -n productx --field-selector type=Warning
```

### Network Testing

#### 1. Test Pod-to-Pod Communication
```bash
# Get pod IPs
kubectl get pods -n productx -o wide

# Test from frontend to backend
kubectl exec <frontend-pod> -n productx -- curl http://backend-svc:8080/actuator/health

# Test DNS resolution
kubectl exec <frontend-pod> -n productx -- nslookup backend-svc
```

#### 2. Test External Access
```bash
# Get ingress URL
INGRESS_URL=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test backend through ingress
curl http://$INGRESS_URL/api/actuator/health

# Test frontend through ingress
curl http://$INGRESS_URL/
```

---

## Production Testing

### Prerequisites
```bash
# Set domain
DOMAIN="www.tranduchuy.site"
API_BASE="https://$DOMAIN/api"
```

### Health Checks

#### 1. Backend Health
```bash
# Actuator health endpoint
curl https://$DOMAIN/api/actuator/health

# Expected response:
# {"status":"UP"}

# Detailed health (if enabled)
curl https://$DOMAIN/api/actuator/health/readiness
curl https://$DOMAIN/api/actuator/health/liveness
```

#### 2. Frontend Health
```bash
# Root path
curl -I https://$DOMAIN/

# Expected: HTTP/2 200
```

### API Testing

#### 1. CRUD Operations
```bash
# List all products
curl https://$DOMAIN/api/products

# Get single product
curl https://$DOMAIN/api/products/1

# Create product
curl -X POST https://$DOMAIN/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Test Product",
    "price": 199.99,
    "color": "Green",
    "category": "Test",
    "stock": 5,
    "description": "Created in production test",
    "image": "https://via.placeholder.com/150"
  }'

# Update product (replace {id} with actual ID)
curl -X PUT https://$DOMAIN/api/products/{id} \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Production Test",
    "price": 249.99,
    "color": "Yellow",
    "category": "Test",
    "stock": 10,
    "description": "Updated in production test",
    "image": "https://via.placeholder.com/150"
  }'

# Delete product
curl -X DELETE https://$DOMAIN/api/products/{id}
```

#### 2. Performance Testing
```bash
# Measure response time
curl -w "\nTime Total: %{time_total}s\n" -o /dev/null -s https://$DOMAIN/api/products

# Test with multiple requests
for i in {1..10}; do
  curl -w "Request $i: %{time_total}s\n" -o /dev/null -s https://$DOMAIN/api/products
done
```

### SSL/TLS Testing

#### 1. Certificate Validation
```bash
# Check certificate
openssl s_client -connect $DOMAIN:443 -servername $DOMAIN < /dev/null

# Check certificate expiry
echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -dates

# Test SSL Labs (online)
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN
```

#### 2. HTTPS Redirect
```bash
# Test HTTP to HTTPS redirect
curl -I http://$DOMAIN/

# Expected: HTTP/1.1 301 Moved Permanently
# Location: https://$DOMAIN/
```

### End-to-End Testing

#### Complete User Flow
```bash
#!/bin/bash
set -e

DOMAIN="www.tranduchuy.site"
API_BASE="https://$DOMAIN/api"

echo "=== E2E Test Suite ==="

# Test 1: Frontend loads
echo "Test 1: Frontend loads"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/)
if [ "$STATUS" = "200" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL (HTTP $STATUS)"
  exit 1
fi

# Test 2: Backend health
echo "Test 2: Backend health"
HEALTH=$(curl -s $API_BASE/actuator/health | jq -r '.status')
if [ "$HEALTH" = "UP" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL (Status: $HEALTH)"
  exit 1
fi

# Test 3: List products
echo "Test 3: List products"
PRODUCTS=$(curl -s $API_BASE/products)
COUNT=$(echo $PRODUCTS | jq 'length')
if [ "$COUNT" -gt 0 ]; then
  echo "✅ PASS (Found $COUNT products)"
else
  echo "❌ FAIL (No products found)"
  exit 1
fi

# Test 4: Create product
echo "Test 4: Create product"
NEW_PRODUCT=$(curl -s -X POST $API_BASE/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "E2E Test Product",
    "price": 99.99,
    "color": "Blue",
    "category": "Test",
    "stock": 10,
    "description": "E2E test",
    "image": "https://via.placeholder.com/150"
  }')
PRODUCT_ID=$(echo $NEW_PRODUCT | jq -r '.id')
if [ -n "$PRODUCT_ID" ] && [ "$PRODUCT_ID" != "null" ]; then
  echo "✅ PASS (Created product ID: $PRODUCT_ID)"
else
  echo "❌ FAIL (Could not create product)"
  exit 1
fi

# Test 5: Update product
echo "Test 5: Update product"
UPDATED=$(curl -s -X PUT $API_BASE/products/$PRODUCT_ID \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated E2E Test",
    "price": 149.99,
    "color": "Red",
    "category": "Test",
    "stock": 20,
    "description": "Updated",
    "image": "https://via.placeholder.com/150"
  }')
UPDATED_NAME=$(echo $UPDATED | jq -r '.name')
if [ "$UPDATED_NAME" = "Updated E2E Test" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
  exit 1
fi

# Test 6: Delete product
echo "Test 6: Delete product"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $API_BASE/products/$PRODUCT_ID)
if [ "$HTTP_CODE" = "204" ]; then
  echo "✅ PASS"
else
  echo "❌ FAIL (HTTP $HTTP_CODE)"
  exit 1
fi

echo ""
echo "=== All Tests Passed! ==="
```

Save as `e2e-test.sh` and run:
```bash
chmod +x e2e-test.sh
./e2e-test.sh
```

---

## Load Testing

### Using Apache Bench (ab)

#### 1. Install
```bash
sudo apt-get install apache2-utils
```

#### 2. Run Load Tests
```bash
# Test GET /api/products
ab -n 1000 -c 10 https://$DOMAIN/api/products

# Test with keep-alive
ab -n 1000 -c 10 -k https://$DOMAIN/api/products

# Test POST (create product)
ab -n 100 -c 5 -p product.json -T application/json https://$DOMAIN/api/products
```

Create `product.json`:
```json
{
  "name": "Load Test Product",
  "price": 99.99,
  "color": "Blue",
  "category": "Test",
  "stock": 10,
  "description": "Load test",
  "image": "https://via.placeholder.com/150"
}
```

### Using k6

#### 1. Install
```bash
sudo apt-get install k6
```

#### 2. Create Test Script
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 users
    { duration: '1m', target: 10 },   // Stay at 10 users
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
};

export default function () {
  // Test GET /api/products
  let res = http.get('https://www.tranduchuy.site/api/products');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
```

#### 3. Run Test
```bash
k6 run load-test.js
```

---

## Security Testing

### 1. OWASP ZAP Scan
```bash
# Install ZAP
docker pull owasp/zap2docker-stable

# Run baseline scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://$DOMAIN \
  -r zap-report.html

# Run full scan
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t https://$DOMAIN \
  -r zap-full-report.html
```

### 2. SQL Injection Testing
```bash
# Test with malicious input
curl -X POST https://$DOMAIN/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test'\'' OR 1=1--",
    "price": 99.99,
    "color": "Blue",
    "category": "Test",
    "stock": 10
  }'

# Should return validation error, not SQL error
```

### 3. XSS Testing
```bash
# Test with script injection
curl -X POST https://$DOMAIN/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<script>alert(\"XSS\")</script>",
    "price": 99.99,
    "color": "Blue",
    "category": "Test",
    "stock": 10
  }'

# Should be sanitized or rejected
```

---

## Monitoring During Tests

### Watch Kubernetes Resources
```bash
# Watch pods
watch kubectl get pods -n productx

# Watch HPA
watch kubectl get hpa -n productx

# Watch events
kubectl get events -n productx --watch
```

### Check Grafana Dashboards
```bash
# Get Grafana URL
kubectl get ingress -n monitoring

# Open in browser and check:
# - CPU usage
# - Memory usage
# - Request rate
# - Error rate
# - Response time
```

---

## Troubleshooting Test Failures

### Backend Not Responding
```bash
# Check pod status
kubectl get pods -n productx -l app=backend

# Check logs
kubectl logs -l app=backend -n productx --tail=100

# Check database connection
kubectl exec <backend-pod> -n productx -- curl http://localhost:8080/actuator/health
```

### Frontend Not Loading
```bash
# Check pod status
kubectl get pods -n productx -l app=frontend

# Check nginx logs
kubectl logs -l app=frontend -n productx --tail=100

# Test nginx config
kubectl exec <frontend-pod> -n productx -- nginx -t
```

### Database Connection Issues
```bash
# Test from backend pod
kubectl exec <backend-pod> -n productx -- nc -zv <db-host> 5432

# Check database logs
ssh ec2-user@<db-host>
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

---

## Automated Testing Script

Save as `test-all.sh`:
```bash
#!/bin/bash

echo "=== ProductX Test Suite ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

DOMAIN="www.tranduchuy.site"
PASSED=0
FAILED=0

test_endpoint() {
  local name=$1
  local url=$2
  local expected=$3
  
  echo -n "Testing $name... "
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  
  if [ "$STATUS" = "$expected" ]; then
    echo -e "${GREEN}✅ PASS${NC}"
    ((PASSED++))
  else
    echo -e "${RED}❌ FAIL (Expected $expected, got $STATUS)${NC}"
    ((FAILED++))
  fi
}

# Run tests
test_endpoint "Frontend" "https://$DOMAIN/" "200"
test_endpoint "Backend Health" "https://$DOMAIN/api/actuator/health" "200"
test_endpoint "List Products" "https://$DOMAIN/api/products" "200"
test_endpoint "Get Product" "https://$DOMAIN/api/products/1" "200"

echo ""
echo "=== Results ==="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi
```

Run:
```bash
chmod +x test-all.sh
./test-all.sh
```
