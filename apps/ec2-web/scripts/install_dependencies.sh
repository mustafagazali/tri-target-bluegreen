#!/usr/bin/env bash
set -euo pipefail
dnf -y install python3
pip3 install -r /opt/ec2-web/requirements.txt || true
cp /opt/ec2-web/systemd.service /etc/systemd/system/ec2-web.service
systemctl daemon-reload