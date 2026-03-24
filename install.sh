#!/bin/bash
set -e

BASE="https://raw.githubusercontent.com/nagbabalik/panel_installer/main"

echo "======================================"
echo "🚀 TAMJ INSTALLER DOWNLOADING FILES"
echo "======================================"

cd /root || exit

echo "[1/5] Downloading core..."
curl -fsSL $BASE/core.sh -o core.sh

echo "[2/5] Downloading panel..."
curl -fsSL $BASE/panel.sh -o panel.sh

echo "[3/5] Downloading api..."
curl -fsSL $BASE/api.sh -o api.sh

echo "[4/5] Downloading vps..."
curl -fsSL $BASE/vps.sh -o vps.sh

echo "[5/5] Setting permissions..."
chmod +x core.sh panel.sh api.sh vps.sh

echo "======================================"
echo "🚀 RUNNING INSTALLER"
echo "======================================"

bash core.sh
bash panel.sh
bash api.sh
bash vps.sh
