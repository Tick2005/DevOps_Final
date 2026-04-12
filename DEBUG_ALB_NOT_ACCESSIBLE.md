# 🔍 Debug: ALB/Domain Không Truy Cập Được

## 📋 Checklist Kiểm Tra

### 1. Kiểm tra Ingress có ADDRESS chưa

```bash
kubectl get ingress -n productx
```

**Output mong đợi:**
```
NAME          CLASS   HOSTS             ADDRESS                                    PORTS   AGE
app-ingress   alb     tranduchuy.site   k8s-productx-xxx.ap-southeast-1.elb...    80,443  10m
```

**Nếu ADDRESS trống:**
- ALB chưa được tạo
- Check Load Balancer Controller logs

### 2. Kiểm tra ALB trên AWS Console

**AWS Console:**
1. EC2 → Load Balancers
2. Tìm ALB có tên `k8s-productx-*`
3. Check:
   - State: **active** ✅
   - Availability Zones: 2 AZs
   - Listeners: Port 80 (HTTP) và 443 (HTTPS)

**AWS CLI:**
```bash
aws elbv2 describe-load-balancers \
  --region ap-southeast-1 \
  --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-productx')]" \
  --output table
```

### 3. Kiểm tra Target Groups

```bash
# List target groups
aws elbv2 describe-target-groups \
  --region ap-southeast-1 \
  --query "TargetGroups[?contains(TargetGroupName, 'k8s-productx')]" \
  --output table

# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --region ap-southeast-1 \
  --query "TargetGroups[?contains(TargetGroupName, 'k8s-productx')].TargetGroupArn" \
  --output text | head -1)

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region ap-southeast-1
```

**Target health phải là `healthy`:**
```json
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.0.x.x",
                "Port": 80
            },
            "HealthCheckPort": "80",
            "TargetHealth": {
                "State": "healthy"  // ✅ Phải là healthy
            }
        }
    ]
}
```

**Nếu `unhealthy` hoặc `initial`:**
- Pods chưa ready
- Health check path sai
- Security Groups block traffic

### 4. Kiểm tra Pods đang chạy

```bash
# Check pods
kubectl get pods -n productx

# Check pod logs
kubectl logs -n productx deployment/frontend --tail=50
kubectl logs -n productx deployment/backend --tail=50

# Check pod status
kubectl describe pod -n productx <pod-name>
```

**Pods phải RUNNING:**
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx                 1/1     Running   0          10m
frontend-xxx                1/1     Running   0          10m
```

### 5. Kiểm tra Services

```bash
kubectl get svc -n productx
```

**Output mong đợi:**
```
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
backend-svc    ClusterIP   172.20.x.x      <none>        8080/TCP   10m
frontend-svc   ClusterIP   172.20.x.x      <none>        80/TCP     10m
```

**Test service từ trong cluster:**
```bash
# Get a pod to test from
kubectl run -it --rm debug --image=busybox --restart=Never -n productx -- sh

# Inside the pod:
wget -O- http://frontend-svc.productx.svc.cluster.local
wget -O- http://backend-svc.productx.svc.cluster.local:8080/api/products
```

### 6. Kiểm tra DNS Resolution

```bash
# Check domain resolves to ALB
nslookup tranduchuy.site

# Check ALB DNS
ALB_DNS=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB DNS: $ALB_DNS"
nslookup $ALB_DNS
```

**Domain phải point đến ALB:**
```
Server:  8.8.8.8
Address: 8.8.8.8#53

Non-authoritative answer:
Name:    tranduchuy.site
Address: <ALB-IP-1>
Address: <ALB-IP-2>
```

### 7. Kiểm tra Security Groups

**ALB Security Group phải allow:**
- Inbound: Port 80 (HTTP) từ 0.0.0.0/0
- Inbound: Port 443 (HTTPS) từ 0.0.0.0/0
- Outbound: All traffic

**Check qua AWS CLI:**
```bash
# Get ALB security groups
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region ap-southeast-1 \
  --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-productx')].LoadBalancerArn" \
  --output text)

aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region ap-southeast-1 \
  --query "LoadBalancers[0].SecurityGroups"

# Check security group rules
SG_ID="<security-group-id-from-above>"
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --region ap-southeast-1
```

### 8. Test ALB trực tiếp

```bash
# Get ALB DNS
ALB_DNS=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test HTTP
curl -v http://$ALB_DNS/

# Test HTTPS
curl -v https://$ALB_DNS/

# Test với Host header
curl -v -H "Host: tranduchuy.site" http://$ALB_DNS/
```

### 9. Kiểm tra Ingress Configuration

```bash
# Get ingress details
kubectl describe ingress app-ingress -n productx

# Check annotations
kubectl get ingress app-ingress -n productx -o yaml
```

**Annotations quan trọng:**
```yaml
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing  # ✅ Phải là internet-facing
  alb.ingress.kubernetes.io/target-type: ip
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
  alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...  # Certificate ARN
```

### 10. Kiểm tra Load Balancer Controller Logs

```bash
# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=100

# Check for errors
kubectl logs -n kube-system deployment/aws-load-balancer-controller | grep -i error
```

---

## 🔧 Common Issues & Fixes

### Issue 1: Target Groups Unhealthy

**Nguyên nhân:**
- Pods chưa ready
- Health check path không đúng
- Security Groups block traffic từ ALB đến pods

**Fix:**
```bash
# Check pod readiness
kubectl get pods -n productx

# Check health check configuration
kubectl describe ingress app-ingress -n productx | grep healthcheck

# Update health check path nếu cần
kubectl annotate ingress app-ingress -n productx \
  alb.ingress.kubernetes.io/healthcheck-path=/ \
  --overwrite
```

### Issue 2: ALB Security Group Không Allow Traffic

**Fix qua AWS Console:**
1. EC2 → Load Balancers → Select ALB
2. Security tab → Click security group
3. Inbound rules → Edit
4. Add rules:
   - Type: HTTP, Port: 80, Source: 0.0.0.0/0
   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0

**Fix qua AWS CLI:**
```bash
SG_ID="<alb-security-group-id>"

# Add HTTP rule
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region ap-southeast-1

# Add HTTPS rule
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --region ap-southeast-1
```

### Issue 3: Pods Không Chạy

**Check:**
```bash
# Get pod status
kubectl get pods -n productx

# Describe pod
kubectl describe pod -n productx <pod-name>

# Check logs
kubectl logs -n productx <pod-name>
```

**Common issues:**
- ImagePullBackOff: Docker image không tồn tại
- CrashLoopBackOff: Application lỗi
- Pending: Không đủ resources

**Fix:**
```bash
# Restart deployment
kubectl rollout restart deployment/frontend -n productx
kubectl rollout restart deployment/backend -n productx

# Check deployment status
kubectl rollout status deployment/frontend -n productx
kubectl rollout status deployment/backend -n productx
```

### Issue 4: DNS Không Resolve

**Check Hostinger DNS:**
1. Login Hostinger
2. Domains → tranduchuy.site → DNS
3. Verify A record:
   - Type: A
   - Name: @ (hoặc tranduchuy.site)
   - Points to: <ALB-IP>
   - TTL: 300

**Lấy ALB IP:**
```bash
ALB_DNS=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
nslookup $ALB_DNS | grep Address | tail -1 | awk '{print $2}'
```

**Hoặc dùng CNAME:**
- Type: CNAME
- Name: @ (hoặc www)
- Points to: <ALB-DNS-name>
- TTL: 300

**Wait for DNS propagation:**
```bash
# Check DNS propagation
dig tranduchuy.site

# Check from different DNS servers
nslookup tranduchuy.site 8.8.8.8
nslookup tranduchuy.site 1.1.1.1
```

### Issue 5: Certificate Issues

**Check certificate:**
```bash
# Get certificate ARN from ingress
kubectl get ingress app-ingress -n productx -o yaml | grep certificate-arn

# Check certificate status
aws acm describe-certificate \
  --certificate-arn <cert-arn> \
  --region ap-southeast-1 \
  --query "Certificate.Status"
```

**Status phải là `ISSUED`**

**Nếu `PENDING_VALIDATION`:**
- Thêm CNAME record vào Hostinger DNS
- Đợi validation (5-30 phút)

---

## 🎯 Quick Debug Script

Chạy script này để check tất cả:

```bash
#!/bin/bash

echo "=== 1. Ingress Status ==="
kubectl get ingress -n productx

echo -e "\n=== 2. Pods Status ==="
kubectl get pods -n productx

echo -e "\n=== 3. Services ==="
kubectl get svc -n productx

echo -e "\n=== 4. ALB DNS ==="
ALB_DNS=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB DNS: $ALB_DNS"

echo -e "\n=== 5. Test ALB HTTP ==="
curl -I http://$ALB_DNS/ 2>&1 | head -5

echo -e "\n=== 6. DNS Resolution ==="
nslookup tranduchuy.site | grep -A2 "Non-authoritative"

echo -e "\n=== 7. Target Groups ==="
aws elbv2 describe-target-groups \
  --region ap-southeast-1 \
  --query "TargetGroups[?contains(TargetGroupName, 'k8s-productx')].{Name:TargetGroupName,Port:Port,Health:HealthCheckPath}" \
  --output table

echo -e "\n=== 8. Load Balancer Controller ==="
kubectl get deployment -n kube-system aws-load-balancer-controller
```

---

## 📞 Cần thêm thông tin

Hãy chạy các lệnh sau và gửi output cho tôi:

```bash
# 1. Ingress details
kubectl describe ingress app-ingress -n productx

# 2. Pods status
kubectl get pods -n productx -o wide

# 3. ALB info
aws elbv2 describe-load-balancers \
  --region ap-southeast-1 \
  --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-productx')]" \
  --output json

# 4. Target health
TG_ARN=$(aws elbv2 describe-target-groups --region ap-southeast-1 --query "TargetGroups[?contains(TargetGroupName, 'k8s-productx')].TargetGroupArn" --output text | head -1)
aws elbv2 describe-target-health --target-group-arn $TG_ARN --region ap-southeast-1

# 5. Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=50
```

Gửi output của các lệnh trên để tôi debug chi tiết hơn!
