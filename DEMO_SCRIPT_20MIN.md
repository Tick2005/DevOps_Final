# 🎬 Demo Script - CI/CD Pipeline (20 Minutes)

## 📋 Pre-Demo Checklist

### ✅ Before Recording:
- [ ] Infrastructure đã deploy xong (EKS, Database, NFS)
- [ ] Application đang chạy version v1.0.0 hoặc v1.0.1
- [ ] Domain accessible: https://www.tranduchuy.site
- [ ] Grafana accessible: https://monitoring.tranduchuy.site
- [ ] GitHub repository ready
- [ ] Browser tabs prepared:
  - Tab 1: GitHub repository
  - Tab 2: GitHub Actions
  - Tab 3: Application (https://www.tranduchuy.site)
  - Tab 4: Grafana (https://monitoring.tranduchuy.site)
- [ ] Terminal/kubectl ready
- [ ] Screen recording software ready

---

## 🎯 Demo Timeline (20 Minutes)

| Time | Section | Duration |
|------|---------|----------|
| 0:00-2:00 | Introduction & Current State | 2 min |
| 2:00-4:00 | 5.1 Source Code Modification | 2 min |
| 4:00-5:00 | 5.2 Commit & Push | 1 min |
| 5:00-10:00 | 5.3 CI Pipeline Execution | 5 min |
| 10:00-13:00 | 5.4 CD Pipeline & Deployment | 3 min |
| 13:00-15:00 | 5.5 Verification | 2 min |
| 15:00-17:00 | 5.6 Monitoring Validation | 2 min |
| 17:00-19:30 | 5.7 Failure Simulation | 2.5 min |
| 19:30-20:00 | Summary & Q&A | 0.5 min |

---

## 📝 Detailed Script

### **[0:00-2:00] Introduction & Current State** (2 minutes)

**Script:**
```
"Xin chào, tôi là [Tên]. Hôm nay tôi sẽ demo hệ thống CI/CD pipeline 
cho ứng dụng ProductX được deploy trên Kubernetes (EKS).

Hệ thống hiện tại đang chạy với kiến trúc Tier 5 - Kubernetes-based 
architecture, bao gồm:
- EKS Cluster trên AWS
- PostgreSQL Database
- NFS Storage
- Prometheus & Grafana Monitoring
- Automated CI/CD với GitHub Actions

Hãy xem ứng dụng đang chạy..."
```

**Actions:**
1. Mở browser → https://www.tranduchuy.site
2. Chỉ vào "Runtime Info" panel:
   - **Version: v1.0.1** (hoặc version hiện tại)
   - Status: Online
   - Tier: Tier 5 - Kubernetes-Based Architecture
3. Scroll qua Product List để show app đang hoạt động
4. Nhấn vào "Add Product" để show form

**Say:**
```
"Như các bạn thấy, ứng dụng đang chạy version v1.0.1, 
status Online, và đang chạy trên Kubernetes.

Bây giờ tôi sẽ thực hiện một thay đổi source code để demo 
CI/CD pipeline tự động."
```

---

### **[2:00-4:00] 5.1 Source Code Modification** (2 minutes)

**Script:**
```
"Tôi sẽ thay đổi validation rule trong ProductRequest.java 
để loại bỏ giới hạn kích thước ảnh. Hiện tại, hệ thống 
chỉ cho phép upload ảnh tối đa 100KB."
```

**Actions:**

1. **Mở VS Code / IDE**
2. **Navigate to file:**
   ```
   DevOps_Final/app/backend/common/src/main/java/com/startupx/common/product/ProductRequest.java
   ```

3. **Show current code (line 27):**
   ```java
   @Size(max = 100000, message = "image data too large (max 100KB)")
   private String image;
   ```

4. **Explain:**
   ```
   "Dòng 27 này giới hạn kích thước ảnh tối đa 100KB. 
   Tôi sẽ comment dòng này để loại bỏ giới hạn."
   ```

5. **Make the change:**
   ```java
   // @Size(max = 100000, message = "image data too large (max 100KB)")
   private String image;
   ```

6. **Save file** (Ctrl+S)

**Say:**
```
"Thay đổi đã được thực hiện. Bây giờ tôi sẽ commit và push 
lên repository để trigger CI/CD pipeline."
```

---

### **[4:00-5:00] 5.2 Commit & Push** (1 minute)

**Script:**
```
"Tôi sẽ commit thay đổi với message rõ ràng và push lên 
nhánh main để trigger pipeline."
```

**Actions:**

1. **Open Terminal**

2. **Git commands:**
   ```bash
   cd DevOps_Final
   
   # Check status
   git status
   
   # Add file
   git add app/backend/common/src/main/java/com/startupx/common/product/ProductRequest.java
   
   # Commit with clear message
   git commit -m "Remove image size validation limit"
   
   # Push to main branch
   git push origin main
   ```

3. **Show output:**
   ```
   [main abc1234] Remove image size validation limit
    1 file changed, 1 insertion(+), 1 deletion(-)
   To github.com:username/DevOps_Final.git
      def5678..abc1234  main -> main
   ```

**Say:**
```
"Code đã được push lên repository. Pipeline sẽ tự động 
trigger trong vài giây nữa."
```

---

### **[5:00-10:00] 5.3 CI Pipeline Execution** (5 minutes)

**Script:**
```
"Bây giờ chúng ta sẽ theo dõi CI pipeline. Pipeline này 
sẽ thực hiện build, test, security scan, và push Docker images."
```

**Actions:**

1. **Switch to GitHub Actions tab**
   - URL: https://github.com/[username]/DevOps_Final/actions

2. **Show workflow starting:**
   ```
   "Build & Release Docker" workflow
   Status: In progress (yellow dot)
   Triggered by: push event
   Commit: "Remove image size validation limit"
   ```

3. **Click vào workflow run**

4. **Show jobs:**
   ```
   ✓ wait-for-infrastructure (completed)
   ⏳ build-backend (in progress)
   ⏳ build-frontend (queued)
   ```

5. **Click vào "build-backend" job**

6. **Explain each step as it runs:**

   **Step 1: Checkout Repository**
   ```
   "Đầu tiên, pipeline checkout source code từ repository."
   ```

   **Step 2: Setup Java 21**
   ```
   "Setup Java 21 với Maven caching để tăng tốc độ build."
   ```

   **Step 3: Build Application JAR**
   ```
   "Build JAR file từ source code. Bước này sẽ compile code 
   và tạo artifact."
   ```
   - Show: `mvn clean package -DskipTests`
   - Show: `BUILD SUCCESS`

   **Step 4: Setup Docker Buildx**
   ```
   "Setup Docker Buildx để build multi-platform images."
   ```

   **Step 5: Login to Docker Hub**
   ```
   "Đăng nhập Docker Hub để push images."
   ```

   **Step 6: Extract Docker Metadata**
   ```
   "Tạo tags cho Docker image dựa trên commit SHA."
   ```
   - Show tags: `sha-abc1234`, `latest`

   **Step 7: Build and Load Backend Image**
   ```
   "Build Docker image và load vào local để scan security."
   ```

   **Step 8: Run Trivy Vulnerability Scanner** ⚠️ **IMPORTANT**
   ```
   "Đây là bước security scanning. Trivy sẽ scan Docker image 
   để tìm vulnerabilities. Nếu có CRITICAL vulnerabilities, 
   pipeline sẽ fail."
   ```
   - Show: Trivy scanning output
   - Show: No CRITICAL vulnerabilities found
   - Show: ✅ Security scan PASSED

   **Step 9: Push Backend Image to Docker Hub**
   ```
   "Image đã pass security scan, bây giờ push lên Docker Hub."
   ```
   - Show: Pushing layers
   - Show: ✅ Image pushed successfully

   **Step 10: Print Backend Image Info**
   ```
   "Hiển thị thông tin image đã được publish."
   ```
   - Show: Image tags
   - Show: Commit SHA

7. **Show build-frontend job** (briefly)
   ```
   "Frontend job cũng thực hiện tương tự: build, scan, push."
   ```
   - Show: ✅ All steps completed

8. **Show workflow summary:**
   ```
   ✅ wait-for-infrastructure
   ✅ build-backend (3m 45s)
   ✅ build-frontend (2m 30s)
   
   Total time: ~5 minutes
   ```

**Say:**
```
"CI pipeline đã hoàn thành thành công. Tất cả security checks 
đã pass. Bây giờ CD pipeline sẽ tự động trigger để deploy 
lên production."
```

---

### **[10:00-13:00] 5.4 CD Pipeline & Deployment** (3 minutes)

**Script:**
```
"CD pipeline sẽ tự động deploy version mới lên Kubernetes cluster."
```

**Actions:**

1. **Show "Continuous Deployment (CD)" workflow starting**
   - Status: In progress
   - Triggered by: workflow_run (Build & Release Docker completed)

2. **Click vào workflow run**

3. **Show jobs:**
   ```
   ✓ version-management (completed)
   ⏳ deploy (in progress)
   ```

4. **Click vào "version-management" job**

5. **Show version increment:**
   ```
   🔍 Checking if app files have changed...
   ✅ App files have changed
   
   📋 Current version: v1.0.1
   ✅ New version: v1.0.2
   
   ============================================
   📦 VERSION UPDATE
   ============================================
   Previous: v1.0.1
   New:      v1.0.2
   Reason:   App files changed
   ============================================
   ```

**Say:**
```
"Version tự động tăng từ v1.0.1 lên v1.0.2 vì có thay đổi 
trong thư mục app/."
```

6. **Click vào "deploy" job**

7. **Explain key steps:**

   **Update ConfigMap with New Version**
   ```
   "Cập nhật ConfigMap với version mới v1.0.2."
   ```

   **Update Deployment Images**
   ```
   "Cập nhật deployment với Docker images mới (tag: sha-abc1234)."
   ```

   **Deploy Application**
   ```
   "Deploy lên Kubernetes với rolling update strategy."
   ```
   - Show: `kubectl apply -f ...`
   - Show: `kubectl rollout restart deployment/backend`
   - Show: `kubectl rollout status deployment/backend`

   **Wait for Pods to be Ready**
   ```
   "Đợi pods mới ready trước khi chạy health checks."
   ```

   **Health Check - Backend API**
   ```
   "Kiểm tra backend API health endpoint."
   ```
   - Show: ✅ Pod health check successful
   - Show: ✅ Service health check successful

   **Health Check - Frontend**
   ```
   "Kiểm tra frontend health."
   ```
   - Show: ✅ Frontend is healthy

   **Smoke Tests - CRUD Operations** ⚠️ **IMPORTANT**
   ```
   "Chạy smoke tests để verify CRUD operations."
   ```
   - Show: Test 1: GET /api/products ✅
   - Show: Test 2: GET /api/products/:id ✅
   - Show: Test 3: POST /api/products ✅
   - Show: Test 4: PUT /api/products/:id ✅
   - Show: Test 5: DELETE /api/products/:id ✅
   - Show: 🎉 All smoke tests PASSED!

8. **Show deployment summary:**
   ```
   ============================================
   🎉 DEPLOYMENT COMPLETED!
   ============================================
   Version: v1.0.1 → v1.0.2
   Backend Image: username/productx-backend:sha-abc1234
   Frontend Image: username/productx-frontend:sha-abc1234
   ============================================
   ```

**Say:**
```
"Deployment hoàn thành thành công! Version v1.0.2 đã được 
deploy lên production. Bây giờ chúng ta sẽ verify."
```

---

### **[13:00-15:00] 5.5 Verification of Application Update** (2 minutes)

**Script:**
```
"Bây giờ tôi sẽ verify rằng version mới đã được deploy 
và thay đổi source code đã có hiệu lực."
```

**Actions:**

1. **Switch to Application tab**
   - URL: https://www.tranduchuy.site

2. **Refresh page** (F5)

3. **Check Runtime Info:**
   ```
   Version: v1.0.2 ✅ (changed from v1.0.1)
   Status: Online
   Host: [pod-name]
   Source: Kubernetes
   Tier: Tier 5 - Kubernetes-Based Architecture
   ```

**Say:**
```
"Như các bạn thấy, version đã thay đổi từ v1.0.1 lên v1.0.2. 
Bây giờ tôi sẽ verify rằng validation đã được loại bỏ."
```

4. **Test the change:**
   - Click "Add Product"
   - Fill form:
     - Name: "Large Image Test"
     - Price: 999
     - Color: "Red"
     - Category: "Test"
     - Stock: 10
     - Description: "Testing large image upload"
     - Image: Paste a large base64 image (>100KB)
   
5. **Click "Add Product"**

6. **Show result:**
   ```
   ✅ Product added successfully!
   (Trước đây sẽ báo lỗi: "image data too large (max 100KB)")
   ```

**Say:**
```
"Perfect! Ứng dụng đã chấp nhận ảnh lớn hơn 100KB. 
Thay đổi source code đã có hiệu lực."
```

7. **Verify HTTPS:**
   - Click vào address bar
   - Show: 🔒 Secure | https://www.tranduchuy.site
   - Click vào lock icon
   - Show: Certificate valid

**Say:**
```
"Ứng dụng chỉ accessible qua HTTPS với valid certificate."
```

---

### **[15:00-17:00] 5.6 Monitoring & Observability Validation** (2 minutes)

**Script:**
```
"Bây giờ tôi sẽ show monitoring system để confirm rằng 
ứng dụng đang được observe."
```

**Actions:**

1. **Switch to Grafana tab**
   - URL: https://monitoring.tranduchuy.site

2. **Login (if needed):**
   - Username: admin
   - Password: [from secret]

3. **Navigate to Dashboard:**
   - Click "Dashboards" → "Browse"
   - Select "Kubernetes / Compute Resources / Namespace (Pods)"
   - Filter: namespace = "productx"

4. **Show metrics:**

   **CPU Usage:**
   ```
   "Đây là CPU usage của các pods trong namespace productx."
   ```
   - Point to graph showing CPU metrics
   - Show: backend pods, frontend pods

   **Memory Usage:**
   ```
   "Memory consumption của các pods."
   ```
   - Point to memory graph
   - Show: Current usage vs limits

   **Pod Status:**
   ```
   "Status của các pods. Tất cả đang running."
   ```
   - Show: Pod count
   - Show: All pods healthy (green)

   **Network Traffic:**
   ```
   "Network traffic in/out của các pods."
   ```
   - Show: Request rate
   - Show: Response time

5. **Switch to another dashboard:**
   - Select "Kubernetes / Compute Resources / Cluster"
   - Show: Overall cluster health

**Say:**
```
"Như các bạn thấy, monitoring system đang thu thập metrics 
real-time từ production environment. Tất cả pods đang healthy 
và hoạt động bình thường."
```

---

### **[17:00-19:30] 5.7 Failure Simulation & System Behaviour** (2.5 minutes)

**Script:**
```
"Bây giờ tôi sẽ simulate một failure scenario để demonstrate 
operational resilience của hệ thống."
```

**Actions:**

1. **Open Terminal**

2. **Show current pods:**
   ```bash
   kubectl get pods -n productx
   ```
   
   **Output:**
   ```
   NAME                        READY   STATUS    RESTARTS   AGE
   backend-7d9f8b5c6d-abc12    1/1     Running   0          5m
   backend-7d9f8b5c6d-def34    1/1     Running   0          5m
   frontend-6c8d7b4a5e-ghi56   1/1     Running   0          5m
   frontend-6c8d7b4a5e-jkl78   1/1     Running   0          5m
   ```

**Say:**
```
"Hiện tại có 2 backend pods và 2 frontend pods đang running. 
Tôi sẽ delete một backend pod để simulate failure."
```

3. **Delete a backend pod:**
   ```bash
   kubectl delete pod backend-7d9f8b5c6d-abc12 -n productx
   ```
   
   **Output:**
   ```
   pod "backend-7d9f8b5c6d-abc12" deleted
   ```

4. **Immediately check pods:**
   ```bash
   kubectl get pods -n productx -w
   ```
   
   **Output (watch mode):**
   ```
   NAME                        READY   STATUS        RESTARTS   AGE
   backend-7d9f8b5c6d-abc12    1/1     Terminating   0          5m
   backend-7d9f8b5c6d-def34    1/1     Running       0          5m
   backend-7d9f8b5c6d-mno90    0/1     Pending       0          0s  ← New pod
   backend-7d9f8b5c6d-mno90    0/1     ContainerCreating   0   1s
   backend-7d9f8b5c6d-mno90    1/1     Running       0          15s ← Ready!
   ```

**Say:**
```
"Như các bạn thấy, Kubernetes tự động tạo một pod mới để 
thay thế pod bị xóa. Deployment controller đảm bảo luôn 
có đúng số lượng replicas."
```

5. **Switch to Application tab**
   - Refresh page multiple times
   - Show: Application vẫn hoạt động bình thường
   - Show: Version vẫn là v1.0.2
   - Show: No downtime

**Say:**
```
"Ứng dụng vẫn accessible và hoạt động bình thường. 
Không có downtime vì còn pod khác đang serve traffic."
```

6. **Switch to Grafana tab**
   - Refresh dashboard
   - Show: Pod count graph
   - Point to the dip and recovery

**Say:**
```
"Trong Grafana, chúng ta có thể thấy pod count giảm xuống 
rồi tự động recover về 2 pods."
```

7. **Check pod logs (optional):**
   ```bash
   kubectl logs -l app=backend -n productx --tail=10
   ```
   
   **Show:** Application logs from new pod

8. **Final verification:**
   ```bash
   kubectl get pods -n productx
   ```
   
   **Output:**
   ```
   NAME                        READY   STATUS    RESTARTS   AGE
   backend-7d9f8b5c6d-def34    1/1     Running   0          7m
   backend-7d9f8b5c6d-mno90    1/1     Running   0          2m  ← New pod
   frontend-6c8d7b4a5e-ghi56   1/1     Running   0          7m
   frontend-6c8d7b4a5e-jkl78   1/1     Running   0          7m
   ```

**Say:**
```
"Hệ thống đã tự động recover. Đây là self-healing capability 
của Kubernetes."
```

---

### **[19:30-20:00] Summary & Conclusion** (0.5 minute)

**Script:**
```
"Tóm lại, trong demo này tôi đã demonstrate:

✅ 5.1 Source Code Modification - Loại bỏ image size validation
✅ 5.2 Commit & Push - Push code lên repository với clear message
✅ 5.3 CI Pipeline - Build, security scan, push Docker images
✅ 5.4 CD Pipeline - Tự động deploy lên Kubernetes với version v1.0.2
✅ 5.5 Verification - Verify thay đổi đã có hiệu lực trên production
✅ 5.6 Monitoring - Show real-time metrics trong Grafana
✅ 5.7 Failure Simulation - Demonstrate self-healing capability

Hệ thống CI/CD hoàn toàn automated, từ code commit đến production 
deployment, với security scanning, health checks, và monitoring.

Cảm ơn các bạn đã theo dõi!"
```

---

## 📌 Important Notes

### ⚠️ Potential Issues & Solutions:

1. **Pipeline takes too long:**
   - Skip waiting for full completion
   - Show key steps and explain the rest
   - Use "fast-forward" in video editing

2. **Deployment fails:**
   - Have a backup plan: show rollback mechanism
   - Explain the failure and how system handles it
   - This actually demonstrates resilience!

3. **Application not accessible:**
   - Check DNS propagation
   - Use ALB hostname as backup
   - Explain DNS caching

4. **Grafana shows no data:**
   - Wait 1-2 minutes for metrics to appear
   - Explain metric collection interval
   - Show Prometheus targets as alternative

### 🎯 Time Management Tips:

- **Practice multiple times** to stay within 20 minutes
- **Prepare screenshots** as backup if live demo fails
- **Use 2 monitors** - one for demo, one for script
- **Have terminal commands ready** in a text file
- **Bookmark all URLs** for quick access

### 📹 Recording Tips:

- **Use high resolution** (1080p minimum)
- **Zoom in** when showing code or terminal
- **Speak clearly** and not too fast
- **Pause briefly** between sections
- **Show cursor** to guide viewer attention
- **Use annotations** in post-production if needed

---

## 🎬 Pre-Recording Checklist

### Day Before:
- [ ] Run full workflow to ensure everything works
- [ ] Check all URLs are accessible
- [ ] Verify Grafana credentials
- [ ] Prepare test data for product creation
- [ ] Practice the script 2-3 times

### 1 Hour Before:
- [ ] Clear browser cache
- [ ] Close unnecessary applications
- [ ] Disable notifications
- [ ] Check internet connection
- [ ] Test screen recording software
- [ ] Prepare backup plan

### Just Before Recording:
- [ ] Open all required tabs
- [ ] Position windows properly
- [ ] Check audio levels
- [ ] Take a deep breath
- [ ] Start recording!

---

**Good luck with your demo! 🚀**
