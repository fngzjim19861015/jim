#!/bin/bash
set -e
# === Install cloudflared ===
if [ ! -f /usr/local/bin/cloudflared ]; then
  curl -fsSL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
  chmod +x /usr/local/bin/cloudflared
fi

# === Install Xray ===
if [ ! -f /usr/local/bin/xray ]; then
  bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

# === Write Xray WS config ===
cat > /usr/local/etc/xray/config.json << 'XEOF'
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": 10000,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "85925f10-6fc4-4baa-a28e-37ea53113f1b"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {"path": "/ws"}
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
XEOF

# === Start services ===
pkill cloudflared 2>/dev/null || true
systemctl stop xray 2>/dev/null || true
nohup cloudflared tunnel --url http://localhost:10000 > /tmp/cf.log 2>&1 &
sleep 8
systemctl start xray
systemctl enable xray
echo "DEPLOY_OK"
