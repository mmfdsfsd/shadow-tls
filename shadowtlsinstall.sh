#!/bin/bash

set -e

BIN_PATH="/root/shadowtls"
SERVICE_FILE="/etc/systemd/system/shadowtls.service"
DOWNLOAD_URL="https://github.com/mmfdsfsd/shadow-tls/releases/download/v0.2.25/shadow-tls-x86_64-unknown-linux-musl"

echo "=============================="
echo " ShadowTLS 一键安装脚本"
echo "=============================="
echo ""
echo "请选择操作："
echo "1) 安装 ShadowTLS"
echo "2) 卸载 ShadowTLS"
read -p "请输入选项 [1-2] (默认:1): " ACTION
ACTION=${ACTION:-1}

if [[ "$ACTION" == "2" ]]; then
    echo ""
    echo "开始卸载 ShadowTLS..."

    # 停止服务
    systemctl stop shadowtls 2>/dev/null || true

    # 禁用开机启动
    systemctl disable shadowtls 2>/dev/null || true

    # 删除 service 文件
    rm -f /etc/systemd/system/shadowtls.service

    # 删除程序
    rm -f /root/shadowtls

    # 重载 systemd
    systemctl daemon-reload

    echo ""
    echo "✅ 卸载完成！"
    exit 0
fi

# ===== 交互输入函数 =====
read_input() {
    local prompt="$1"
    local default="$2"
    read -p "${prompt} (默认: ${default}): " input
    echo "${input:-$default}"
}

echo ""
echo "请输入运行参数（直接回车使用默认值）"

LISTEN=$(read_input "监听地址 --listen" "0.0.0.0:443")
SERVER=$(read_input "转发地址 --server" "127.0.0.1:8080")
TLS=$(read_input "伪装域名 --tls" "www.microsoft.com")
PASSWORD=$(read_input "密码 --password" "123456")

echo ""
echo "=============================="
echo "参数确认："
echo "LISTEN   = $LISTEN"
echo "SERVER   = $SERVER"
echo "TLS      = $TLS"
echo "PASSWORD = $PASSWORD"
echo "=============================="
echo ""

read -p "确认安装？(y/n): " confirm
[[ "$confirm" != "y" ]] && exit 0

# ===== 下载程序 =====
echo "[1/4] 下载 shadowtls..."
curl -L -o ${BIN_PATH} ${DOWNLOAD_URL}

chmod +x ${BIN_PATH}

# ===== 创建 systemd 服务 =====
echo "[2/4] 创建 systemd 服务..."

cat > ${SERVICE_FILE} <<EOF
[Unit]
Description=ShadowTLS Service
After=network.target

[Service]
Type=simple
ExecStart=${BIN_PATH} --v3 server --listen ${LISTEN} --server ${SERVER} --tls ${TLS} --password ${PASSWORD}
Restart=always
RestartSec=3
LimitNOFILE=512000

[Install]
WantedBy=multi-user.target
EOF

# ===== 重载 systemd =====
echo "[3/4] 重载 systemd..."
systemctl daemon-reexec
systemctl daemon-reload

# ===== 启动服务 =====
echo "[4/4] 启动服务..."
systemctl enable shadowtls
systemctl restart shadowtls

echo ""
echo "✅ 安装完成！"
echo ""

# ===== 状态信息 =====
systemctl status shadowtls --no-pager

echo ""
echo "常用命令："
echo "启动: systemctl start shadowtls"
echo "停止: systemctl stop shadowtls"
echo "重启: systemctl restart shadowtls"
echo "状态: systemctl status shadowtls"
echo "日志: journalctl -u shadowtls -f"
