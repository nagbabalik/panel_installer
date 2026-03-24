#!/bin/bash
set -e
PANEL_IP=$(hostname -I | awk '{print $1}')
cat > /var/www/vpn-panel/install/tamj-user-sync-vps.sh <<EOF
#!/bin/bash
set -e
PANEL_USERS_URL="http://${PANEL_IP}/api/users.php"
API_KEY="SERVER1_SECRET_KEY"
apt update -y
apt install -y curl jq
echo "sync-only installer ready"
EOF
chmod 755 /var/www/vpn-panel/install/tamj-user-sync-vps.sh

cat > /usr/local/bin/tamj-vps-stats-collector.php <<'EOF'
<?php
$pdo = new PDO("mysql:host=localhost;dbname=vpn_panel;charset=utf8mb4","tamj","StrongPass123",[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
$vpsList = $pdo->query("SELECT * FROM vpn_vps ORDER BY id DESC LIMIT 10")->fetchAll();
foreach($vpsList as $v){
  $stmt=$pdo->prepare("INSERT INTO vps_stats_cache (vps_id,host,name,status,cpu,ram,disk,users_online,rx_kbs,tx_kbs,rx_human,tx_human,uptime,loadavg,raw_output) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE host=VALUES(host),name=VALUES(name),status=VALUES(status),cpu=VALUES(cpu),ram=VALUES(ram),disk=VALUES(disk),users_online=VALUES(users_online),rx_kbs=VALUES(rx_kbs),tx_kbs=VALUES(tx_kbs),rx_human=VALUES(rx_human),tx_human=VALUES(tx_human),uptime=VALUES(uptime),loadavg=VALUES(loadavg),raw_output=VALUES(raw_output),updated_at=CURRENT_TIMESTAMP");
  $stmt->execute([$v['id'],$v['host'],$v['name']?:'--',$v['status'],0,0,0,0,0,0,'0 KB/s','0 KB/s','--','--','cache placeholder']);
}
EOF
chmod +x /usr/local/bin/tamj-vps-stats-collector.php
cat > /usr/local/bin/tamj-stats-runner.sh <<'EOF'
#!/bin/bash
php /usr/local/bin/tamj-vps-stats-collector.php >/dev/null 2>&1 || true
EOF
chmod +x /usr/local/bin/tamj-stats-runner.sh
( crontab -l 2>/dev/null | grep -v "tamj-stats-runner.sh" ; echo "*/1 * * * * /usr/local/bin/tamj-stats-runner.sh" ) | crontab -
cat > /usr/local/bin/tamj-job-worker.php <<'EOF'
<?php
$pdo = new PDO("mysql:host=localhost;dbname=vpn_panel;charset=utf8mb4","tamj","StrongPass123",[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
while(true){ sleep(5); }
EOF
chmod +x /usr/local/bin/tamj-job-worker.php
cat > /etc/systemd/system/tamj-job-worker.service <<'EOF'
[Unit]
Description=TAMJ Queue-Pro Job Worker
After=network.target mariadb.service
[Service]
ExecStart=/usr/bin/php /usr/local/bin/tamj-job-worker.php
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now tamj-job-worker
/usr/local/bin/tamj-stats-runner.sh || true
