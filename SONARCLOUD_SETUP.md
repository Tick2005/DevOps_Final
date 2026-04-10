# HƯỚNG DẪN CẤU HÌNH SONARCLOUD

## 📋 Tổng quan

SonarCloud là dịch vụ code quality analysis miễn phí cho public repositories. Nó thay thế SonarQube server (cần EC2 instance) trong kiến trúc này.

## ✅ Ưu điểm so với SonarQube

| Tiêu chí | SonarQube | SonarCloud |
|----------|-----------|------------|
| Chi phí | Cần EC2 instance (~$30/tháng) | Miễn phí cho public repos |
| Quản lý | Phải tự cài đặt và maintain | Fully managed |
| Cập nhật | Phải tự update | Tự động update |
| Tích hợp | Cần cấu hình webhook | Native GitHub integration |
| Bảo mật | Phải tự quản lý | AWS-grade security |

## 🚀 Bước 1: Đăng ký SonarCloud

### 1.1. Truy cập SonarCloud

1. Vào https://sonarcloud.io
2. Click **Log in** → **With GitHub**
3. Authorize SonarCloud truy cập GitHub account

### 1.2. Tạo Organization

1. Sau khi đăng nhập, click **+** → **Create new organization**
2. Chọn một trong hai cách:
   - **Import a GitHub organization**: Nếu bạn có GitHub organization
   - **Create a manual organization**: Tạo organization mới

**Ví dụ tạo manual organization:**
- Organization Key: `my-devops-org` (chỉ chữ thường, số, dấu gạch ngang)
- Display Name: `My DevOps Organization`
- Choose a plan: **Free plan** (cho public repos)

3. Click **Create Organization**

### 1.3. Lưu Organization Key

Lưu lại Organization Key, bạn sẽ cần nó cho `.env` file:
```bash
SONAR_ORGANIZATION=my-devops-org
```

## 🔧 Bước 2: Tạo Project

### 2.1. Import từ GitHub (Khuyến nghị)

1. Trong organization vừa tạo, click **Analyze new project**
2. Click **Import from GitHub**
3. Authorize SonarCloud truy cập repositories
4. Chọn repository `DevOps_Final`
5. Click **Set Up**

### 2.2. Hoặc tạo Manual Project

1. Click **+** → **Analyze new project** → **Create project manually**
2. Điền thông tin:
   - Project key: `my-devops-org_DevOps_Final`
   - Display name: `ProductX Management System`
3. Click **Set Up**

### 2.3. Lưu Project Key

Lưu lại Project Key:
```bash
SONAR_PROJECT_KEY=my-devops-org_DevOps_Final
```

## 🔑 Bước 3: Tạo Token

### 3.1. Generate Token

1. Click vào avatar (góc phải trên) → **My Account**
2. Vào tab **Security**
3. Trong phần **Generate Tokens**:
   - Name: `productx-ci`
   - Type: **User Token**
   - Expires in: **No expiration** (hoặc chọn thời gian)
4. Click **Generate**

### 3.2. Lưu Token

⚠️ **QUAN TRỌNG**: Token chỉ hiển thị 1 lần, copy và lưu ngay!

```bash
SONAR_TOKEN=squ_abc123def456ghi789jkl012mno345pqr678
```

## 📝 Bước 4: Cấu hình Project

### 4.1. Disable Automatic Analysis

1. Trong project, vào **Administration** → **Analysis Method**
2. Tắt **Automatic Analysis**
3. Chọn **GitHub Actions** (hoặc **With other CI tools**)

Lý do: Chúng ta sẽ chạy analysis trong CI/CD pipeline, không cần automatic analysis.

### 4.2. Cấu hình Quality Gate (Optional)

1. Vào **Quality Gates** → **Set as Default**
2. Hoặc tạo custom Quality Gate:
   - **Administration** → **Quality Gates** → **Create**
   - Đặt tên: `ProductX Quality Gate`
   - Add conditions:
     - Coverage: >= 80%
     - Duplicated Lines: <= 3%
     - Maintainability Rating: A
     - Reliability Rating: A
     - Security Rating: A

### 4.3. Cấu hình New Code Definition

1. Vào **Administration** → **New Code**
2. Chọn **Previous version** hoặc **Number of days**: 30

## 🔗 Bước 5: Tích hợp với GitHub Actions

### 5.1. Thêm Secrets vào GitHub

Vào GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Thêm 3 secrets:

```
SONAR_TOKEN=squ_abc123def456ghi789jkl012mno345pqr678
SONAR_ORGANIZATION=my-devops-org
SONAR_PROJECT_KEY=my-devops-org_DevOps_Final
```

### 5.2. Kiểm tra Workflow

File `.github/workflows/main-ci.yml` đã được cấu hình sẵn:

```yaml
- name: SonarCloud Scan
  working-directory: ./app/backend/common
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  run: |
    mvn sonar:sonar \
      -Dsonar.projectKey=${{ secrets.SONAR_PROJECT_KEY }} \
      -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }} \
      -Dsonar.host.url=https://sonarcloud.io \
      -Dsonar.token=${{ secrets.SONAR_TOKEN }}
```

### 5.3. Test Integration

1. Push code lên GitHub:
   ```bash
   git add .
   git commit -m "Configure SonarCloud"
   git push origin main
   ```

2. Vào **Actions** tab trên GitHub, xem workflow chạy

3. Sau khi workflow hoàn thành, vào SonarCloud project để xem kết quả

## 📊 Bước 6: Xem Kết quả Analysis

### 6.1. Dashboard

Trên SonarCloud project dashboard, bạn sẽ thấy:

- **Bugs**: Số lỗi trong code
- **Vulnerabilities**: Lỗ hổng bảo mật
- **Code Smells**: Code không tối ưu
- **Coverage**: Test coverage %
- **Duplications**: Code trùng lặp %
- **Security Hotspots**: Điểm cần review về security

### 6.2. Quality Gate Status

- **Passed**: Code đạt tiêu chuẩn ✅
- **Failed**: Code không đạt tiêu chuẩn ❌

### 6.3. Pull Request Decoration

Khi tạo Pull Request, SonarCloud sẽ tự động:
- Comment kết quả analysis
- Hiển thị Quality Gate status
- Highlight các issues mới

## 🔧 Bước 7: Cấu hình nâng cao

### 7.1. Exclude Files

Tạo file `sonar-project.properties` (đã có sẵn):

```properties
sonar.exclusions=**/node_modules/**,**/target/**,**/dist/**,**/*.test.js
sonar.coverage.exclusions=**/*.test.js,**/*.test.jsx,**/test/**
```

### 7.2. Cấu hình cho Frontend

Nếu muốn analyze cả frontend, thêm vào workflow:

```yaml
- name: Frontend Tests with Coverage
  working-directory: ./app/frontend
  run: |
    npm run test -- --coverage

- name: SonarCloud Scan Frontend
  uses: SonarSource/sonarcloud-github-action@master
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### 7.3. Branch Analysis

SonarCloud tự động analyze:
- Main branch
- Pull Requests
- Feature branches (nếu cấu hình)

## 📈 Bước 8: Badges

### 8.1. Thêm Badge vào README

1. Vào SonarCloud project → **Information** → **Get project badges**
2. Copy markdown code
3. Paste vào `README.md`:

```markdown
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=my-devops-org_DevOps_Final&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=my-devops-org_DevOps_Final)

[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=my-devops-org_DevOps_Final&metric=bugs)](https://sonarcloud.io/summary/new_code?id=my-devops-org_DevOps_Final)

[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=my-devops-org_DevOps_Final&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=my-devops-org_DevOps_Final)

[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=my-devops-org_DevOps_Final&metric=coverage)](https://sonarcloud.io/summary/new_code?id=my-devops-org_DevOps_Final)
```

## 🐛 Xử lý sự cố

### Issue 1: "Project not found"

**Nguyên nhân**: Project key hoặc organization sai

**Xử lý**:
1. Kiểm tra lại `SONAR_PROJECT_KEY` và `SONAR_ORGANIZATION`
2. Đảm bảo không có khoảng trắng thừa
3. Kiểm tra project có tồn tại trên SonarCloud

### Issue 2: "Insufficient privileges"

**Nguyên nhân**: Token không có quyền

**Xử lý**:
1. Tạo token mới với quyền **Execute Analysis**
2. Update GitHub Secret `SONAR_TOKEN`

### Issue 3: "Quality Gate failed"

**Nguyên nhân**: Code không đạt tiêu chuẩn

**Xử lý**:
1. Xem chi tiết issues trên SonarCloud
2. Fix các bugs, vulnerabilities, code smells
3. Tăng test coverage
4. Push lại code

### Issue 4: "Analysis timeout"

**Nguyên nhân**: Project quá lớn hoặc mạng chậm

**Xử lý**:
1. Tăng timeout trong workflow:
   ```yaml
   timeout-minutes: 30
   ```
2. Exclude các thư mục không cần analyze

## 📚 Tài liệu tham khảo

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [SonarCloud GitHub Action](https://github.com/SonarSource/sonarcloud-github-action)
- [SonarScanner for Maven](https://docs.sonarcloud.io/advanced-setup/ci-based-analysis/sonarscanner-for-maven/)
- [Quality Gates](https://docs.sonarcloud.io/improving/quality-gates/)

## 💡 Tips

1. **Chạy local analysis** (optional):
   ```bash
   cd app/backend/common
   mvn clean verify sonar:sonar \
     -Dsonar.projectKey=my-devops-org_DevOps_Final \
     -Dsonar.organization=my-devops-org \
     -Dsonar.host.url=https://sonarcloud.io \
     -Dsonar.token=YOUR_TOKEN
   ```

2. **Xem history**: Vào **Activity** tab để xem lịch sử analysis

3. **Compare branches**: Vào **Branches** tab để so sánh các branches

4. **Set up notifications**: Vào **My Account** → **Notifications** để nhận email khi Quality Gate failed

---

**Hoàn thành! SonarCloud đã sẵn sàng analyze code của bạn. 🎉**
