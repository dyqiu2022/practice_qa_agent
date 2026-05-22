#!/bin/bash
set -e

PROJECT_DIR="/home/joey/practice_qa_agent"

echo "=== 1. 检查前端构建产物 ==="
if [ ! -d "$PROJECT_DIR/frontend/dist" ]; then
    echo "dist/ 目录不存在，先构建前端..."
    cd "$PROJECT_DIR/frontend"
    npm install
    npm run build
fi

echo "=== 2. 启动 FastAPI 后端 ==="
cd "$PROJECT_DIR/backend"
pip install -q fastapi uvicorn pydantic
uvicorn main:app --host 127.0.0.1 --port 8000 &
BACKEND_PID=$!
echo "FastAPI PID: $BACKEND_PID"

echo "=== 3. 测试 Nginx 配置 ==="
nginx -t -c "$PROJECT_DIR/nginx.conf"

echo "=== 4. 启动 Nginx ==="
nginx -c "$PROJECT_DIR/nginx.conf"
echo "Nginx 已启动 (PID: $(cat /var/run/nginx.pid 2>/dev/null || echo 'unknown'))"

echo ""
echo "========================================"
echo "  访问 http://localhost"
echo "  FastAPI 后端: http://localhost:8000"
echo "========================================"
echo ""
echo "按 Ctrl+C 停止所有服务"

trap "echo '正在停止...'; kill $BACKEND_PID 2>/dev/null; nginx -s stop -c $PROJECT_DIR/nginx.conf 2>/dev/null; exit 0" INT TERM

wait
