#!/bin/bash
#国内 Ubuntu 22.04 LTS 一键安装Docker
#sudo ./install_docker_guolei.sh

set -e

echo "🔧 开始在 Ubuntu 22.04 上安装 Docker（国内源版）..."

# 检查系统版本
if [[ $(lsb_release -is) != "Ubuntu" ]] || [[ $(lsb_release -rs) != "22.04" ]]; then
  echo "❌ 本脚本仅支持 Ubuntu 22.04 LTS，当前为 $(lsb_release -ds)"
  exit 1
fi

# 检查 root
if [[ $EUID -ne 0 ]]; then
  echo "❌ 请使用 root 用户或通过 sudo 运行此脚本：sudo $0"
  exit 1
fi

# 卸载旧版本
echo "🔍 卸载旧版本 Docker..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

# 更新 apt
echo "🔄 更新 apt 包索引..."
apt-get update -y

# 安装依赖
echo "📦 安装依赖..."
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

# 添加阿里云 Docker GPG key
echo "🔐 添加阿里云 Docker GPG 密钥..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 设置阿里云 Docker apt 源
echo "📡 设置阿里云 Docker 仓库..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新 apt
apt-get update -y

# 安装 Docker CE
echo "🚀 安装 Docker Engine..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动服务
echo "🔧 启动 Docker 服务..."
systemctl enable docker
systemctl start docker

# 将当前用户加入 docker 组
if ! groups "$SUDO_USER" | grep -qw docker; then
  echo "👤 正在将用户 $SUDO_USER 添加到 docker 用户组..."
  usermod -aG docker "$SUDO_USER"
  echo "⚠️ 请注销并重新登录，或者执行 'newgrp docker' 以立即生效"
fi

# 验证
echo "🧪 验证 Docker..."
if docker --version &> /dev/null; then
  echo "✅ Docker 安装成功：$(docker --version)"
else
  echo "❌ Docker 安装失败，请检查日志"
  exit 1
fi
