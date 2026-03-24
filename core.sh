#!/bin/bash
set -e
apt update -y
apt install -y nginx mariadb-server php8.2-fpm php8.2-mysql php8.2-cli php8.2-curl php8.2-mbstring php8.2-zip php8.2-xml php8.2-gd curl jq unzip tzdata openssh-client sshpass cron rsync procps net-tools
systemctl enable --now nginx mariadb php8.2-fpm cron
timedatectl set-timezone Asia/Manila 2>/dev/null || true
ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
echo Asia/Manila > /etc/timezone
rm -rf /var/www/vpn-panel
mkdir -p /var/www/vpn-panel/{admin,api,assets,install}
mkdir -p /var/log/tamj-vps
mkdir -p /usr/local/bin
mysql -e "DROP DATABASE IF EXISTS vpn_panel;" || true
mysql -e "DROP USER IF EXISTS 'tamj'@'localhost';" || true
mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS vpn_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'tamj'@'localhost' IDENTIFIED BY 'StrongPass123';
ALTER USER 'tamj'@'localhost' IDENTIFIED BY 'StrongPass123';
GRANT ALL PRIVILEGES ON vpn_panel.* TO 'tamj'@'localhost';
FLUSH PRIVILEGES;
USE vpn_panel;
CREATE TABLE admins (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50) UNIQUE NOT NULL, password VARCHAR(255) NOT NULL, role ENUM('admin','subadmin') NOT NULL DEFAULT 'admin', status TINYINT NOT NULL DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(32) UNIQUE, password VARCHAR(255), expiry DATE, status TINYINT NOT NULL DEFAULT 1, max_login INT NOT NULL DEFAULT 1, device_id VARCHAR(128) DEFAULT NULL, device_model VARCHAR(128) DEFAULT NULL, created_by INT DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, last_seen DATETIME NULL, last_ip VARCHAR(64) NULL, last_user_agent VARCHAR(255) NULL, session_token VARCHAR(128) DEFAULT NULL);
CREATE TABLE vpn_vps (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(80) DEFAULT NULL, host VARCHAR(128) NOT NULL, ssh_user VARCHAR(64) NOT NULL DEFAULT 'root', ssh_port INT NOT NULL DEFAULT 22, ssh_pass TEXT NOT NULL, status ENUM('NEW','QUEUED','INSTALLING','ONLINE','OFFLINE','ERROR') NOT NULL DEFAULT 'NEW', install_mode ENUM('full-vpn','sync-only','custom-script') NOT NULL DEFAULT 'sync-only', custom_script LONGTEXT NULL, vpn_script_url TEXT NULL, last_log VARCHAR(255) DEFAULT '', last_check DATETIME NULL, created_by INT DEFAULT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);
CREATE TABLE user_sessions (id BIGINT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(64) NOT NULL, device_id VARCHAR(128) DEFAULT NULL, ip_address VARCHAR(64) DEFAULT NULL, user_agent VARCHAR(255) DEFAULT NULL, session_token VARCHAR(128) DEFAULT NULL, vps_host VARCHAR(128) DEFAULT NULL, is_active TINYINT NOT NULL DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);
CREATE TABLE vps_stats_cache (id INT AUTO_INCREMENT PRIMARY KEY, vps_id INT NOT NULL, host VARCHAR(128) NOT NULL, name VARCHAR(128) DEFAULT NULL, status VARCHAR(20) NOT NULL DEFAULT 'OFFLINE', cpu DECIMAL(8,2) NOT NULL DEFAULT 0, ram DECIMAL(8,2) NOT NULL DEFAULT 0, disk DECIMAL(8,2) NOT NULL DEFAULT 0, users_online INT NOT NULL DEFAULT 0, rx_kbs DECIMAL(12,2) NOT NULL DEFAULT 0, tx_kbs DECIMAL(12,2) NOT NULL DEFAULT 0, rx_human VARCHAR(32) DEFAULT '0 KB/s', tx_human VARCHAR(32) DEFAULT '0 KB/s', uptime VARCHAR(255) DEFAULT '--', loadavg VARCHAR(255) DEFAULT '--', raw_output MEDIUMTEXT NULL, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, UNIQUE KEY uq_vps_id (vps_id));
CREATE TABLE jobs (id BIGINT AUTO_INCREMENT PRIMARY KEY, type ENUM('install_vps') NOT NULL, payload LONGTEXT NOT NULL, status ENUM('queued','running','done','error') NOT NULL DEFAULT 'queued', output MEDIUMTEXT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);
SQL
ADMIN_HASH=$(php -r "echo password_hash('admin123', PASSWORD_DEFAULT);")
mysql -utamj -pStrongPass123 vpn_panel <<SQL
INSERT INTO admins (username,password,role,status) VALUES ('admin', '${ADMIN_HASH}', 'admin', 1);
SQL
