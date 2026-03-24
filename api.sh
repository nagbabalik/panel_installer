#!/bin/bash
set -e
cat > /var/www/vpn-panel/api/users.php <<'EOF'
<?php header("Content-Type: application/json"); require __DIR__."/../admin/config.php"; $recv=$_SERVER['HTTP_X_API_KEY']??''; if(!hash_equals(API_KEY,$recv)){ http_response_code(403); echo json_encode(["error"=>"forbidden"]); exit; } echo json_encode($pdo->query("SELECT username,password,expiry,status,max_login,device_id,device_model,last_seen,last_ip,last_user_agent,session_token FROM users")->fetchAll()); ?>
EOF
cat > /var/www/vpn-panel/api/active_ips.php <<'EOF'
<?php require __DIR__."/../admin/config.php"; $recv=$_SERVER['HTTP_X_API_KEY']??''; if(!hash_equals(API_KEY,$recv)){ http_response_code(403); echo "forbidden"; exit; } $ips=$pdo->query("SELECT DISTINCT last_ip FROM users WHERE status=1 AND last_ip IS NOT NULL AND last_ip<>'' AND last_seen >= (NOW() - INTERVAL ".ONLINE_SECONDS." SECOND)")->fetchAll(PDO::FETCH_COLUMN); echo implode("\n", array_filter($ips)); ?>
EOF
cat > /var/www/vpn-panel/api/_app_token.php <<'EOF'
<?php require_once __DIR__."/../admin/config.php"; $hdr=$_SERVER['HTTP_X_APP_TOKEN']??''; if(!hash_equals(APP_TOKEN,$hdr)){ http_response_code(403); echo json_encode(["status"=>"forbidden"]); exit; } ?>
EOF
