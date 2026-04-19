#!/bin/bash
#Ubuntu 22.04 LTS 一键安装Docker
#sudo ./install_docker.sh
set -e

echo "🔧 开始在 Ubuntu 22.04 上安装 Docker..."

# 检查是否为 Ubuntu 22.04
if [[ $(lsb_release -is) != "Ubuntu" ]] || [[ $(lsb_release -rs) != "22.04" ]]; then
  echo "❌ 本脚本仅支持 Ubuntu 22.04 LTS，当前为 $(lsb_release -ds)"
  #exit 1
fi

# 检查是否为 root 用户
if [[ $EUID -ne 0 ]]; then
  echo "❌ 请使用 root 用户或通过 sudo 运行此脚本：sudo $0"
  exit 1
fi

# 卸载旧版本（如有）
echo "🔍 检查并卸载旧版本 Docker（如存在）..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

# 更新 apt 包索引
echo "🔄 更新 apt 包索引..."
apt-get update -y

# 安装必要依赖
echo "📦 安装依赖包..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# 添加 Docker 的官方 GPG 密钥
echo "🔐 添加 Docker GPG 密钥..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 设置仓库
echo "📡 设置 Docker 仓库..."
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 再次更新 apt 索引
apt-get update -y

# 安装 Docker Engine
echo "🚀 安装 Docker Engine..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker 并设置开机自启
echo "🔧 启动 Docker 服务..."
systemctl enable docker
systemctl start docker

# 可选：将当前用户加入 docker 组（避免每次都用 sudo）
if ! groups "$SUDO_USER" | grep -qw docker; then
  echo "👤 正在将用户 $SUDO_USER 添加到 docker 用户组..."
  usermod -aG docker "$SUDO_USER"
  echo "⚠️ 请注销并重新登录，或者执行 'newgrp docker' 以立即生效"
fi

# 测试 Docker 是否安装成功
echo "🧪 正在验证 Docker 是否安装成功..."
if docker --version &> /dev/null; then
  echo "✅ Docker 安装成功：$(docker --version)"
else
  echo "❌ Docker 安装失败，请检查上方日志"
  exit 1
fi
