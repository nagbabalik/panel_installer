#!/bin/bash
set -e

BASE="https://raw.githubusercontent.com/nagbabalik/panel_installer/main"

echo "Downloading installer files..."

curl -O $BASE/core.sh
curl -O $BASE/panel.sh
curl -O $BASE/api.sh
curl -O $BASE/vps.sh

chmod +x *.sh

echo "Running installer..."

./core.sh
./panel.sh
./api.sh
./vps.sh
cat > /etc/nginx/sites-available/vpn-panel <<'NGINX'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;
  root /var/www/vpn-panel;
  index index.php;
  location / { try_files $uri $uri/ /admin/login.php; }
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    fastcgi_read_timeout 300s;
    fastcgi_param HTTP_X_API_KEY   $http_x_api_key;
    fastcgi_param HTTP_X_APP_TOKEN $http_x_app_token;
  }
  location ~ /\. { deny all; }
}
NGINX

rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
ln -sf /etc/nginx/sites-available/vpn-panel /etc/nginx/sites-enabled/vpn-panel
nginx -t
systemctl restart nginx php8.2-fpm mariadb cron tamj-job-worker || true
IP=$(hostname -I | awk '{print $1}')
echo "======================================"
echo "✅ TAMJ V3.6 FULL SPLIT INSTALLED"
echo "LOGIN: http://$IP/admin/login.php"
echo "ADMIN: admin / admin123"
echo "======================================"
