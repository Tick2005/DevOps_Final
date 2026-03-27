# DevOps Final

Fullstack Product Management demo dùng Docker Compose:
- Frontend: React + Vite
- Backend: Spring Boot
- Database: MongoDB

## Chạy nhanh
Yêu cầu: Docker Desktop đã chạy.

```bash
docker compose up -d --build
```

Truy cập:
- App: http://localhost:5173
- API: http://localhost:8080/api/products

Dừng hệ thống:

```bash
docker compose down
```

## Cấu trúc chính

```text
app/
  backend/common/   # Spring Boot service
  frontend/         # React + Vite UI
docker-compose.yml
```

## Tính năng chính
- CRUD sản phẩm
- Hiển thị metadata runtime: host, source, tier, version
- UI phân trang và popup chi tiết sản phẩm

## Ghi chú
- Host metadata được resolve động theo request/proxy, phù hợp nhiều môi trường deploy (localhost, domain, VM, cloud).
- Dữ liệu mẫu được seed tự động khi khởi động backend.
