#!/bin/bash

# =============================================================================
# DEBUG CI FAILURE - Kiểm tra lỗi CI workflow
# =============================================================================

set -e

echo "============================================="
echo "🔍 DEBUG CI WORKFLOW FAILURE"
echo "============================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) chưa được cài đặt"
    echo ""
    echo "Cài đặt gh CLI:"
    echo "  - Windows: winget install --id GitHub.cli"
    echo "  - macOS: brew install gh"
    echo "  - Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo ""
    echo "Sau khi cài đặt, chạy: gh auth login"
    echo ""
    echo "============================================="
    echo "📋 MANUAL DEBUGGING STEPS:"
    echo "============================================="
    echo ""
    echo "1. Vào GitHub Actions UI:"
    echo "   https://github.com/YOUR_USERNAME/YOUR_REPO/actions"
    echo ""
    echo "2. Chọn workflow 'Build & Release Docker'"
    echo ""
    echo "3. Click vào lần chạy gần nhất (màu đỏ = failed)"
    echo ""
    echo "4. Xem log của các jobs để tìm lỗi:"
    echo "   - Wait for Infrastructure"
    echo "   - Build Backend Docker Image"
    echo "   - Build Frontend Docker Image"
    echo ""
    echo "============================================="
    echo "🔧 COMMON CI FAILURES:"
    echo "============================================="
    echo ""
    echo "1. Maven Build Failed (Backend):"
    echo "   - Lỗi: Compilation error, dependency issue"
    echo "   - Fix: Check app/backend/common/pom.xml"
    echo ""
    echo "2. NPM Build Failed (Frontend):"
    echo "   - Lỗi: npm ci failed, build error"
    echo "   - Fix: Check app/frontend/package.json"
    echo ""
    echo "3. Trivy Security Scan Failed:"
    echo "   - Lỗi: CRITICAL vulnerabilities found"
    echo "   - Fix: Update dependencies or ignore-unfixed"
    echo ""
    echo "4. Docker Login Failed:"
    echo "   - Lỗi: Invalid credentials"
    echo "   - Fix: Check DOCKER_USERNAME and DOCKER_PASSWORD secrets"
    echo ""
    echo "5. Infrastructure Workflow Still Running:"
    echo "   - Lỗi: Timeout waiting for infrastructure"
    echo "   - Fix: Wait for infrastructure to complete first"
    echo ""
    echo "============================================="
    exit 1
fi

echo "✅ GitHub CLI detected"
echo ""

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI chưa được authenticate"
    echo ""
    echo "Chạy lệnh: gh auth login"
    echo ""
    exit 1
fi

echo "✅ GitHub CLI authenticated"
echo ""

# Get recent CI workflow runs
echo "📊 Recent CI Workflow Runs:"
echo "-------------------------------------------"
gh run list --workflow="main-ci.yml" --limit 5 --json conclusion,status,headSha,createdAt,displayTitle,databaseId \
    --jq '.[] | "\(.databaseId) | \(.conclusion // .status) | \(.displayTitle) | \(.createdAt)"'
echo ""

# Get the latest failed run
FAILED_RUN_ID=$(gh run list --workflow="main-ci.yml" --limit 1 --json conclusion,databaseId \
    --jq '.[] | select(.conclusion=="failure") | .databaseId')

if [ -z "$FAILED_RUN_ID" ]; then
    echo "✅ No failed CI runs found"
    echo ""
    echo "Checking latest run status..."
    LATEST_STATUS=$(gh run list --workflow="main-ci.yml" --limit 1 --json status,conclusion \
        --jq '.[0] | .conclusion // .status')
    echo "Latest run status: $LATEST_STATUS"
    exit 0
fi

echo "❌ Found failed CI run: $FAILED_RUN_ID"
echo ""

# Get detailed logs
echo "============================================="
echo "📋 FAILED RUN DETAILS:"
echo "============================================="
gh run view $FAILED_RUN_ID

echo ""
echo "============================================="
echo "📄 FAILED JOB LOGS:"
echo "============================================="
echo ""
echo "Fetching logs for failed jobs..."
echo ""

# Get failed jobs
FAILED_JOBS=$(gh run view $FAILED_RUN_ID --json jobs \
    --jq '.jobs[] | select(.conclusion=="failure") | .name')

if [ -z "$FAILED_JOBS" ]; then
    echo "⚠️ No failed jobs found (run may still be in progress)"
else
    echo "Failed jobs:"
    echo "$FAILED_JOBS"
    echo ""
    echo "To view full logs, run:"
    echo "  gh run view $FAILED_RUN_ID --log-failed"
fi

echo ""
echo "============================================="
echo "🔧 QUICK FIXES:"
echo "============================================="
echo ""
echo "1. View full error logs:"
echo "   gh run view $FAILED_RUN_ID --log-failed"
echo ""
echo "2. Re-run failed jobs:"
echo "   gh run rerun $FAILED_RUN_ID --failed"
echo ""
echo "3. Re-run entire workflow:"
echo "   gh run rerun $FAILED_RUN_ID"
echo ""
echo "4. Trigger manual CI run:"
echo "   gh workflow run main-ci.yml"
echo ""
echo "============================================="
